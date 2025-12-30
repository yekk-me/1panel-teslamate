package main

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// Config holds the authentication configuration
type Config struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	SecretKey []byte `json:"-"`
}

var (
	config           Config
	configMutex      sync.RWMutex
	configPath       string
	loginTemplate    *template.Template
	settingsTemplate *template.Template
)

func init() {
	// Determine config path
	configPath = getEnv("CONFIG_PATH", "/data/config.json")

	// Try to load config from file first
	if !loadConfigFromFile() {
		// Fall back to environment variables
		config.Username = getEnv("AUTH_USERNAME", "admin")
		config.Password = getEnv("AUTH_PASSWORD", "admin")
	}

	secretKeyStr := getEnv("SECRET_KEY", "")
	if secretKeyStr == "" {
		// Generate a random secret key if not provided
		key := make([]byte, 32)
		rand.Read(key)
		config.SecretKey = key
		log.Println("Warning: SECRET_KEY not set, generated random key. Sessions will not persist across restarts.")
	} else {
		config.SecretKey = []byte(secretKeyStr)
	}

	// Parse templates
	var err error
	loginTemplate, err = template.ParseFiles("/templates/login.html")
	if err != nil {
		loginTemplate, err = template.ParseFiles("templates/login.html")
		if err != nil {
			log.Printf("Warning: Could not load login template: %v", err)
		}
	}

	settingsTemplate, err = template.ParseFiles("/templates/settings.html")
	if err != nil {
		settingsTemplate, err = template.ParseFiles("templates/settings.html")
		if err != nil {
			log.Printf("Warning: Could not load settings template: %v", err)
		}
	}
}

func loadConfigFromFile() bool {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return false
	}
	var fileConfig Config
	if err := json.Unmarshal(data, &fileConfig); err != nil {
		log.Printf("Warning: Could not parse config file: %v", err)
		return false
	}
	if fileConfig.Username != "" && fileConfig.Password != "" {
		config.Username = fileConfig.Username
		config.Password = fileConfig.Password
		log.Printf("Loaded credentials from config file")
		return true
	}
	return false
}

func saveConfigToFile() error {
	configMutex.RLock()
	fileConfig := Config{
		Username: config.Username,
		Password: config.Password,
	}
	configMutex.RUnlock()

	data, err := json.MarshalIndent(fileConfig, "", "  ")
	if err != nil {
		return err
	}

	// Ensure directory exists
	dir := filepath.Dir(configPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	return os.WriteFile(configPath, data, 0600)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// generateSessionToken creates a signed session token
func generateSessionToken(username string, expiry time.Time) string {
	data := username + ":" + expiry.Format(time.RFC3339)
	configMutex.RLock()
	h := hmac.New(sha256.New, config.SecretKey)
	configMutex.RUnlock()
	h.Write([]byte(data))
	signature := hex.EncodeToString(h.Sum(nil))

	token := base64.StdEncoding.EncodeToString([]byte(data)) + "." + signature
	return token
}

// validateSessionToken validates a session token
func validateSessionToken(token string) (string, bool) {
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		return "", false
	}

	dataB64, providedSig := parts[0], parts[1]
	data, err := base64.StdEncoding.DecodeString(dataB64)
	if err != nil {
		return "", false
	}

	// Verify signature
	configMutex.RLock()
	h := hmac.New(sha256.New, config.SecretKey)
	configMutex.RUnlock()
	h.Write(data)
	expectedSig := hex.EncodeToString(h.Sum(nil))
	if !hmac.Equal([]byte(providedSig), []byte(expectedSig)) {
		return "", false
	}

	// Parse and check expiry
	dataParts := strings.SplitN(string(data), ":", 2)
	if len(dataParts) != 2 {
		return "", false
	}
	username := dataParts[0]
	expiryStr := dataParts[1]
	expiry, err := time.Parse(time.RFC3339, expiryStr)
	if err != nil {
		return "", false
	}
	if time.Now().After(expiry) {
		return "", false
	}

	return username, true
}

// isAuthenticated checks if the request has a valid session
func isAuthenticated(r *http.Request) (string, bool) {
	cookie, err := r.Cookie("mytesla_session")
	if err != nil {
		return "", false
	}
	return validateSessionToken(cookie.Value)
}

// authHandler handles ForwardAuth requests from Traefik
func authHandler(w http.ResponseWriter, r *http.Request) {
	username, valid := isAuthenticated(r)
	if !valid {
		log.Printf("Auth check failed: invalid or missing session")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Set forwarded user header for downstream services
	w.Header().Set("X-Forwarded-User", username)
	w.WriteHeader(http.StatusOK)
}

// loginHandler handles login page and form submission
func loginHandler(w http.ResponseWriter, r *http.Request) {
	// If already authenticated, redirect to home
	if _, valid := isAuthenticated(r); valid {
		http.Redirect(w, r, "/", http.StatusFound)
		return
	}

	if r.Method == http.MethodGet {
		renderLoginPage(w, r, "", "")
		return
	}

	if r.Method == http.MethodPost {
		if err := r.ParseForm(); err != nil {
			renderLoginPage(w, r, "Invalid form data", "")
			return
		}

		username := strings.TrimSpace(r.FormValue("username"))
		password := r.FormValue("password")

		configMutex.RLock()
		validCredentials := username == config.Username && password == config.Password
		configMutex.RUnlock()

		if validCredentials {
			// Create session token with 30-day expiry
			expiry := time.Now().Add(30 * 24 * time.Hour)
			token := generateSessionToken(username, expiry)

			// Determine if we should set Secure flag
			isSecure := r.Header.Get("X-Forwarded-Proto") == "https" || r.TLS != nil

			http.SetCookie(w, &http.Cookie{
				Name:     "mytesla_session",
				Value:    token,
				Path:     "/",
				MaxAge:   30 * 24 * 60 * 60, // 30 days
				HttpOnly: true,
				Secure:   isSecure,
				SameSite: http.SameSiteLaxMode,
			})

			// Redirect to original URL or home
			redirectURL := r.URL.Query().Get("rd")
			if redirectURL == "" {
				redirectURL = "/"
			}
			http.Redirect(w, r, redirectURL, http.StatusFound)
			return
		}

		renderLoginPage(w, r, "用户名或密码错误", username)
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

// logoutHandler handles logout requests
func logoutHandler(w http.ResponseWriter, r *http.Request) {
	// Delete session cookie
	http.SetCookie(w, &http.Cookie{
		Name:     "mytesla_session",
		Value:    "",
		Path:     "/",
		MaxAge:   -1,
		HttpOnly: true,
	})

	http.Redirect(w, r, "/login", http.StatusFound)
}

// settingsHandler handles the settings page for changing credentials
func settingsHandler(w http.ResponseWriter, r *http.Request) {
	// Check authentication
	username, valid := isAuthenticated(r)
	if !valid {
		http.Redirect(w, r, "/login?rd=/settings", http.StatusFound)
		return
	}

	if r.Method == http.MethodGet {
		renderSettingsPage(w, username, "", "")
		return
	}

	if r.Method == http.MethodPost {
		if err := r.ParseForm(); err != nil {
			renderSettingsPage(w, username, "表单数据无效", "")
			return
		}

		currentPassword := r.FormValue("current_password")
		newUsername := strings.TrimSpace(r.FormValue("new_username"))
		newPassword := r.FormValue("new_password")
		confirmPassword := r.FormValue("confirm_password")

		// Validate current password
		configMutex.RLock()
		validPassword := currentPassword == config.Password
		configMutex.RUnlock()

		if !validPassword {
			renderSettingsPage(w, username, "当前密码错误", "")
			return
		}

		// Validate new credentials
		if newUsername == "" {
			renderSettingsPage(w, username, "用户名不能为空", "")
			return
		}

		if newPassword != "" && newPassword != confirmPassword {
			renderSettingsPage(w, username, "两次输入的新密码不一致", "")
			return
		}

		// Update credentials
		configMutex.Lock()
		config.Username = newUsername
		if newPassword != "" {
			config.Password = newPassword
		}
		configMutex.Unlock()

		// Save to file
		if err := saveConfigToFile(); err != nil {
			log.Printf("Warning: Could not save config to file: %v", err)
		}

		// Create new session with updated username
		expiry := time.Now().Add(30 * 24 * time.Hour)
		token := generateSessionToken(newUsername, expiry)
		isSecure := r.Header.Get("X-Forwarded-Proto") == "https" || r.TLS != nil

		http.SetCookie(w, &http.Cookie{
			Name:     "mytesla_session",
			Value:    token,
			Path:     "/",
			MaxAge:   30 * 24 * 60 * 60,
			HttpOnly: true,
			Secure:   isSecure,
			SameSite: http.SameSiteLaxMode,
		})

		renderSettingsPage(w, newUsername, "", "凭据已成功更新")
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

type loginPageData struct {
	Error    string
	Username string
	Redirect string
}

func renderLoginPage(w http.ResponseWriter, r *http.Request, errorMsg string, username string) {
	redirectURL := r.URL.Query().Get("rd")
	if redirectURL == "" {
		forwardedURI := r.Header.Get("X-Forwarded-Uri")
		if forwardedURI != "" && forwardedURI != "/login" {
			redirectURL = forwardedURI
		}
	}

	data := loginPageData{
		Error:    errorMsg,
		Username: username,
		Redirect: redirectURL,
	}

	if loginTemplate != nil {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		if err := loginTemplate.Execute(w, data); err != nil {
			log.Printf("Error rendering template: %v", err)
			renderFallbackLoginPage(w, data)
		}
	} else {
		renderFallbackLoginPage(w, data)
	}
}

type settingsPageData struct {
	Username string
	Error    string
	Success  string
}

func renderSettingsPage(w http.ResponseWriter, username, errorMsg, successMsg string) {
	data := settingsPageData{
		Username: username,
		Error:    errorMsg,
		Success:  successMsg,
	}

	if settingsTemplate != nil {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		if err := settingsTemplate.Execute(w, data); err != nil {
			log.Printf("Error rendering template: %v", err)
			renderFallbackSettingsPage(w, data)
		}
	} else {
		renderFallbackSettingsPage(w, data)
	}
}

func renderFallbackLoginPage(w http.ResponseWriter, data loginPageData) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	redirectParam := ""
	if data.Redirect != "" {
		redirectParam = "?rd=" + url.QueryEscape(data.Redirect)
	}

	errorHTML := ""
	if data.Error != "" {
		errorHTML = `<div class="error-message">` + data.Error + `</div>`
	}

	html := `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登录 - MyTesla</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f8fafc;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: #ffffff;
            border-radius: 16px;
            padding: 48px 40px;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
            border: 1px solid #e2e8f0;
        }
        .header { text-align: center; margin-bottom: 32px; }
        .header h1 { font-size: 24px; color: #1a1a1a; font-weight: 700; margin-bottom: 8px; }
        .header p { color: #64748b; font-size: 14px; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; color: #374151; font-size: 14px; font-weight: 500; margin-bottom: 8px; }
        .form-group input {
            width: 100%; padding: 12px 16px; background: #ffffff;
            border: 1px solid #d1d5db; border-radius: 8px;
            font-size: 15px; color: #1a1a1a; outline: none;
        }
        .form-group input:focus { border-color: #8b5cf6; box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1); }
        .submit-btn {
            width: 100%; padding: 12px 16px; background: linear-gradient(135deg, #8b5cf6, #7c3aed);
            border: none; border-radius: 8px; color: #fff; font-size: 15px; font-weight: 600; cursor: pointer;
            margin-top: 8px;
        }
        .submit-btn:hover { background: linear-gradient(135deg, #7c3aed, #6d28d9); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3); }
        .error-message { color: #dc2626; background: #fef2f2; border: 1px solid #fecaca; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; text-align: center; font-size: 14px; }
        .footer { text-align: center; margin-top: 24px; padding-top: 20px; border-top: 1px solid #f1f5f9; }
        .footer p { color: #64748b; font-size: 13px; }
        .footer a { color: #8b5cf6; text-decoration: none; }
        @media (max-width: 480px) {
            body { padding: 16px; align-items: flex-start; padding-top: 60px; }
            .container { padding: 32px 24px; border-radius: 12px; }
            .form-group input, .submit-btn { padding: 14px 16px; font-size: 16px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header"><h1>登录</h1><p>使用您的账户继续访问</p></div>
        ` + errorHTML + `
        <form method="POST" action="/login` + redirectParam + `">
            <div class="form-group">
                <label for="username">用户名</label>
                <input type="text" id="username" name="username" value="` + data.Username + `" placeholder="请输入用户名" required autofocus>
            </div>
            <div class="form-group">
                <label for="password">密码</label>
                <input type="password" id="password" name="password" placeholder="请输入密码" required>
            </div>
            <button type="submit" class="submit-btn">🔐 继续登录</button>
        </form>
        <div class="footer"><p>MyTesla UI design and build by <a href="https://github.com/yekk" target="_blank">yekk</a></p></div>
    </div>
</body>
</html>`
	w.Write([]byte(html))
}

func renderFallbackSettingsPage(w http.ResponseWriter, data settingsPageData) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	errorHTML := ""
	if data.Error != "" {
		errorHTML = `<div class="error-message">` + data.Error + `</div>`
	}
	successHTML := ""
	if data.Success != "" {
		successHTML = `<div class="success-message">` + data.Success + `</div>`
	}

	html := `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>账户设置 - MyTesla</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f8fafc;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: #ffffff;
            border-radius: 16px;
            padding: 48px 40px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
            border: 1px solid #e2e8f0;
        }
        .header { text-align: center; margin-bottom: 28px; }
        .header h1 { font-size: 24px; color: #1a1a1a; font-weight: 700; margin-bottom: 8px; }
        .header p { color: #64748b; font-size: 14px; }
        .section-title { color: #9ca3af; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 16px; }
        .form-group { margin-bottom: 18px; }
        .form-group label { display: block; color: #374151; font-size: 14px; font-weight: 500; margin-bottom: 8px; }
        .form-group input {
            width: 100%; padding: 12px 16px; background: #ffffff;
            border: 1px solid #d1d5db; border-radius: 8px;
            font-size: 15px; color: #1a1a1a; outline: none;
        }
        .form-group input:focus { border-color: #8b5cf6; box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1); }
        .form-group small { display: block; color: #9ca3af; font-size: 12px; margin-top: 6px; }
        .divider { border: none; border-top: 1px solid #f1f5f9; margin: 24px 0; }
        .submit-btn {
            width: 100%; padding: 12px 16px; background: linear-gradient(135deg, #8b5cf6, #7c3aed);
            border: none; border-radius: 8px; color: #fff; font-size: 15px; font-weight: 600; cursor: pointer;
            margin-top: 8px;
        }
        .submit-btn:hover { background: linear-gradient(135deg, #7c3aed, #6d28d9); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3); }
        .footer-links { display: flex; justify-content: center; gap: 20px; margin-top: 24px; padding-top: 20px; border-top: 1px solid #f1f5f9; }
        .footer-links a { color: #64748b; text-decoration: none; font-size: 14px; }
        .footer-links a:hover { color: #8b5cf6; }
        .error-message { color: #dc2626; background: #fef2f2; border: 1px solid #fecaca; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; text-align: center; font-size: 14px; }
        .success-message { color: #16a34a; background: #f0fdf4; border: 1px solid #bbf7d0; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; text-align: center; font-size: 14px; }
        @media (max-width: 480px) {
            body { padding: 16px; align-items: flex-start; padding-top: 40px; }
            .container { padding: 32px 24px; border-radius: 12px; }
            .form-group input, .submit-btn { padding: 14px 16px; font-size: 16px; }
            .footer-links { flex-direction: column; align-items: center; gap: 12px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header"><h1>账户设置</h1><p>修改您的登录凭据</p></div>
        ` + errorHTML + successHTML + `
        <form method="POST" action="/settings">
            <div class="section-title">验证身份</div>
            <div class="form-group">
                <label for="current_password">当前密码 *</label>
                <input type="password" id="current_password" name="current_password" placeholder="请输入当前密码" required>
            </div>
            <hr class="divider">
            <div class="section-title">新凭据</div>
            <div class="form-group">
                <label for="new_username">新用户名</label>
                <input type="text" id="new_username" name="new_username" value="` + data.Username + `" required>
            </div>
            <div class="form-group">
                <label for="new_password">新密码</label>
                <input type="password" id="new_password" name="new_password" placeholder="留空则保持原密码不变">
                <small>如不需要修改密码，请留空</small>
            </div>
            <div class="form-group">
                <label for="confirm_password">确认新密码</label>
                <input type="password" id="confirm_password" name="confirm_password" placeholder="再次输入新密码">
            </div>
            <button type="submit" class="submit-btn">保存更改</button>
        </form>
        <div class="footer-links"><a href="/">返回首页</a><a href="/logout">退出登录</a></div>
    </div>
</body>
</html>`
	w.Write([]byte(html))
}

// healthHandler handles health check requests
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/auth", authHandler)
	mux.HandleFunc("/login", loginHandler)
	mux.HandleFunc("/logout", logoutHandler)
	mux.HandleFunc("/settings", settingsHandler)
	mux.HandleFunc("/health", healthHandler)

	port := getEnv("PORT", "8080")
	log.Printf("Starting auth server on port %s", port)

	configMutex.RLock()
	log.Printf("Initial username: %s", config.Username)
	configMutex.RUnlock()

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
