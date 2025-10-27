#!/bin/bash

# TeslaMate 快速部署脚本
# 一行命令完成部署：bash <(curl -sSL https://your-domain.com/quick-install.sh)

# 下载完整安装脚本
curl -sSL https://raw.githubusercontent.com/your-repo/teslamate-deploy/main/install.sh -o /tmp/teslamate-install.sh

# 赋予执行权限
chmod +x /tmp/teslamate-install.sh

# 执行安装
sudo /tmp/teslamate-install.sh

# 清理临时文件
rm -f /tmp/teslamate-install.sh