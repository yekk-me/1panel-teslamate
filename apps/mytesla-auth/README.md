# MyTesla Auth Service

轻量级的 ForwardAuth 认证服务，为 Traefik 提供 Cookie 持久化登录功能。

## 功能特性

- 🔐 **ForwardAuth 集成** - 与 Traefik ForwardAuth 中间件无缝对接
- 🍪 **Cookie 持久化** - 30 天有效期，关闭浏览器不会丢失登录状态
- 🔒 **安全设计** - HMAC 签名 Session Token，HttpOnly & Secure Cookie
- 🎨 **精美登录页** - 现代化 UI 设计，支持深色主题
- 📱 **PWA 友好** - 完美支持 PWA 模式的持久化认证

## 快速开始

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `AUTH_USERNAME` | 登录用户名 | `admin` |
| `AUTH_PASSWORD` | 登录密码 | `admin` |
| `SECRET_KEY` | Session 签名密钥 | 随机生成 |
| `PORT` | 服务端口 | `8080` |

### Docker 运行

```bash
docker build -t mytesla-auth .
docker run -p 8080:8080 \
  -e AUTH_USERNAME=myuser \
  -e AUTH_PASSWORD=mypassword \
  -e SECRET_KEY=your-secret-key \
  mytesla-auth
```

### Traefik 配置

```yaml
# docker-compose.yml
services:
  auth:
    image: mytesla-auth:latest
    environment:
      - AUTH_USERNAME=${BASIC_AUTH_USER}
      - AUTH_PASSWORD=${BASIC_AUTH_PASS}
      - SECRET_KEY=${AUTH_SECRET_KEY}
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.auth.loadbalancer.server.port=8080"
      # 登录页面路由 (不需要认证)
      - "traefik.http.routers.auth-login.rule=PathPrefix(`/login`) || PathPrefix(`/logout`)"
      - "traefik.http.routers.auth-login.entrypoints=web"
      # ForwardAuth 中间件定义
      - "traefik.http.middlewares.forward-auth.forwardauth.address=http://auth:8080/auth"
      - "traefik.http.middlewares.forward-auth.forwardauth.authResponseHeaders=X-Forwarded-User"

  # 需要认证的服务
  myapp:
    labels:
      - "traefik.http.routers.myapp.middlewares=forward-auth"
```

## API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/auth` | GET | ForwardAuth 验证端点 |
| `/login` | GET/POST | 登录页面和表单提交 |
| `/logout` | GET | 登出并清除 Cookie |
| `/health` | GET | 健康检查 |

## 安全考虑

1. **SECRET_KEY** - 务必在生产环境设置固定的密钥，否则服务重启后所有 Session 失效
2. **HTTPS** - 建议在 HTTPS 环境下使用，Cookie 会自动设置 `Secure` 标志
3. **密码存储** - 当前使用明文对比，适合个人/小团队使用

## License

MIT
