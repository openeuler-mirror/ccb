#!/usr/bin/env bash
# ccb 依赖安装脚本（最小范围：远端命令）
# 原则：配置初始化 + 命令入口 + 自检都放这里，保持 devcontainer.json 简洁
set -euo pipefail
cd /workspace

# 1. 初始化 ccb 配置（默认公网 EulerMaker 网关；账号密码不写入文件）
CONFIG_DIR="${HOME}/.config/cli/defaults"
mkdir -p "${CONFIG_DIR}"
if [ ! -f "${CONFIG_DIR}/config.yaml" ]; then
	cp /workspace/lib/default_config.yaml "${CONFIG_DIR}/config.yaml"
fi

# 2. 可选：内网网关覆盖（CCB_GATEWAY_IP / CCB_GATEWAY_PORT，来自宿主机环境变量）
if [ -n "${CCB_GATEWAY_IP:-}" ]; then
	sed -i "s|^GATEWAY_IP:.*|GATEWAY_IP: ${CCB_GATEWAY_IP}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_GATEWAY_PORT:-}" ]; then
	sed -i "s|^GATEWAY_PORT:.*|GATEWAY_PORT: ${CCB_GATEWAY_PORT}|" "${CONFIG_DIR}/config.yaml"
fi

# 3. 可选：内网 RPM 存储 / job 日志服务覆盖
#    （ccb download 用 SRV_HTTP_REPOSITORIES_*，ccb log 用 SRV_HTTP_RESULT_* 拼 URL）
if [ -n "${CCB_REPOSITORIES_HOST:-}" ]; then
	sed -i "s|^SRV_HTTP_REPOSITORIES_HOST:.*|SRV_HTTP_REPOSITORIES_HOST: ${CCB_REPOSITORIES_HOST}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_REPOSITORIES_PORT:-}" ]; then
	sed -i "s|^SRV_HTTP_REPOSITORIES_PORT:.*|SRV_HTTP_REPOSITORIES_PORT: ${CCB_REPOSITORIES_PORT}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_REPOSITORIES_PROTOCOL:-}" ]; then
	sed -i "s|^SRV_HTTP_REPOSITORIES_PROTOCOL:.*|SRV_HTTP_REPOSITORIES_PROTOCOL: ${CCB_REPOSITORIES_PROTOCOL}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_RESULT_HOST:-}" ]; then
	sed -i "s|^SRV_HTTP_RESULT_HOST:.*|SRV_HTTP_RESULT_HOST: ${CCB_RESULT_HOST}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_RESULT_PORT:-}" ]; then
	sed -i "s|^SRV_HTTP_RESULT_PORT:.*|SRV_HTTP_RESULT_PORT: ${CCB_RESULT_PORT}|" "${CONFIG_DIR}/config.yaml"
fi
if [ -n "${CCB_RESULT_PROTOCOL:-}" ]; then
	sed -i "s|^SRV_HTTP_RESULT_PROTOCOL:.*|SRV_HTTP_RESULT_PROTOCOL: ${CCB_RESULT_PROTOCOL}|" "${CONFIG_DIR}/config.yaml"
fi

# 4. 提供 ccb 命令入口（symlink 到仓库 wrapper，realpath 自动定位仓库根目录）
sudo ln -sf /workspace/sbin/cli/ccb /usr/local/bin/ccb

# 5. bash 历史持久化（命名 volume /commandhistory，重建容器不丢）
if ! grep -q 'HISTFILE=/commandhistory/.bash_history' "${HOME}/.bashrc" 2>/dev/null; then
	printf '\nexport HISTFILE=/commandhistory/.bash_history\n' >>"${HOME}/.bashrc"
fi

# 6. 自检：ruby 版本 + ccb 帮助
ruby -v
ccb -h >/dev/null && echo "ccb 命令可用"

echo "依赖安装完成。"
