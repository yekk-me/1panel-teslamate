# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture
This repository serves as a third-party application store for [1Panel](https://1panel.cn/), specifically for deploying TeslaMate and related services. It contains configuration files that define how these applications run in Docker environments managed by 1Panel.

- **Directory Structure**: `apps/<app-key>/<version>/`
  - `apps/`: Root directory for all applications.
  - `<app-key>`: The unique identifier for the application (e.g., `mytesla`, `mytesla-proxy`).
  - `<version>`: Semantic versioning directory (e.g., `2.1.5`).
- **Core Files**:
  - `data.yml`: Metadata definitions for the app and specific versions (input fields, service dependencies).
  - `docker-compose.yml`: Defines the containers, networks, and volumes.
  - `scripts/`: Lifecycle scripts usually executed by 1Panel during installation or upgrades.

## Deployment & Usage
There are no build or test steps typical of source code repositories. Development involves editing the YAML configurations and testing them in a 1Panel environment.

### Installation
To deploy these configurations to a 1Panel server:

```bash
# Clone the repository
git clone -b main https://github.com/yekk-me/1panel-teslamate /opt/1panel/resource/apps/local/1panel-teslamate

# Install apps into 1Panel local repository
cp -rf /opt/1panel/resource/apps/local/1panel-teslamate/apps/* /opt/1panel/resource/apps/local/

# Cleanup
rm -rf /opt/1panel/resource/apps/local/1panel-teslamate
```

## Available Applications
- **mytesla**: Core TeslaMate application.
- **mytesla-proxy**: Nginx proxy configuration for TeslaMate.
- **mytesla-oversea**: Configuration tailored for overseas access.
- **mytesla-selfhost**: Self-hosted variants (including Sakura and Traefik integrations).
