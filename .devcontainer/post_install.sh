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

# 2. 配置覆盖辅助函数
#    精确匹配 `key:` 后整体替换该行，值中的 & / | / \ 等字符不会被误解释；
#    键不存在时 awk 以非 0 退出，脚本随即失败，避免内网覆盖静默失效
set_config_value() {
	local key="$1" value="$2" file="${CONFIG_DIR}/config.yaml"
	CCB_CONFIG_KEY="${key}" CCB_CONFIG_VALUE="${value}" \
		awk '
		BEGIN {
			key = ENVIRON["CCB_CONFIG_KEY"]
			value = ENVIRON["CCB_CONFIG_VALUE"]
			matched = 0
		}
		substr($0, 1, length(key) + 1) == key ":" {
			matched = 1
			print key ": " value
			next
		}
		{ print }
		END { exit matched ? 0 : 1 }
	' "${file}" >"${file}.tmp" &&
		mv "${file}.tmp" "${file}"
}

# 3. 可选：内网网关覆盖（CCB_GATEWAY_IP / CCB_GATEWAY_PORT，来自宿主机环境变量）
if [ -n "${CCB_GATEWAY_IP:-}" ]; then
	set_config_value "GATEWAY_IP" "${CCB_GATEWAY_IP}"
fi
if [ -n "${CCB_GATEWAY_PORT:-}" ]; then
	set_config_value "GATEWAY_PORT" "${CCB_GATEWAY_PORT}"
fi

# 4. 可选：内网 RPM 存储 / job 日志服务覆盖
#    （ccb download 用 SRV_HTTP_REPOSITORIES_*，ccb log 用 SRV_HTTP_RESULT_* 拼 URL）
if [ -n "${CCB_REPOSITORIES_HOST:-}" ]; then
	set_config_value "SRV_HTTP_REPOSITORIES_HOST" "${CCB_REPOSITORIES_HOST}"
fi
if [ -n "${CCB_REPOSITORIES_PORT:-}" ]; then
	set_config_value "SRV_HTTP_REPOSITORIES_PORT" "${CCB_REPOSITORIES_PORT}"
fi
if [ -n "${CCB_REPOSITORIES_PROTOCOL:-}" ]; then
	set_config_value "SRV_HTTP_REPOSITORIES_PROTOCOL" "${CCB_REPOSITORIES_PROTOCOL}"
fi
if [ -n "${CCB_RESULT_HOST:-}" ]; then
	set_config_value "SRV_HTTP_RESULT_HOST" "${CCB_RESULT_HOST}"
fi
if [ -n "${CCB_RESULT_PORT:-}" ]; then
	set_config_value "SRV_HTTP_RESULT_PORT" "${CCB_RESULT_PORT}"
fi
if [ -n "${CCB_RESULT_PROTOCOL:-}" ]; then
	set_config_value "SRV_HTTP_RESULT_PROTOCOL" "${CCB_RESULT_PROTOCOL}"
fi

# 5. 提供 ccb 命令入口（symlink 到仓库 wrapper，realpath 自动定位仓库根目录）
sudo ln -sf /workspace/sbin/cli/ccb /usr/local/bin/ccb

# 6. bash 历史持久化（命名 volume /commandhistory，重建容器不丢）
if ! grep -q 'HISTFILE=/commandhistory/.bash_history' "${HOME}/.bashrc" 2>/dev/null; then
	printf '\nexport HISTFILE=/commandhistory/.bash_history\n' >>"${HOME}/.bashrc"
fi

# 7. 自检：ruby 版本 + ccb 帮助
#    显式 if 判断，避免 `ccb -h && echo` 的失败被 set -e 对 && 列表的豁免吞掉
ruby -v
if ! ccb -h >/dev/null 2>&1; then
	echo "自检失败：ccb 命令不可用" >&2
	exit 1
fi
echo "ccb 命令可用"

echo "依赖安装完成。"
