# ccb Devcontainer 使用说明

## 这是什么

为 ccb（EulerMaker 客户端 CLI，Ruby）提供的最小范围开发容器，主要价值是**统一 Ruby 版本**：
openEuler 22.03-lts-sp1 自带 ruby 3.0（3.0.3），满足 README 的 2.5+ 要求，避免团队成员各自宿主环境
ruby 版本不一致导致的行为差异。

判定依据：`openeuler-devcontainer` 判定矩阵中 ccb 为 🟡 有条件（宿主安装无痛、必要性低），本次按"团队要统一 Ruby 版本"的前提做最小落地。

## 启动方式

1. VS Code 打开本仓库，命令面板执行 **Reopen in Container**；
2. 或命令行：`devcontainer up --workspace-folder .`（需 devcontainer CLI）。

首次构建会执行 `dnf update` 和 `gem install rest-client`，需要能访问 repo.openeuler.org 与 rubygems.org。

## 范围边界

**支持**（远端命令，容器内可完整使用）：

```
ccb select / create / update / build / build-single / cancel / log / ls / query / download
```

**刻意不做**：

- `ccb local-build` / `ccb local-rebuild`：脚本要求 `docker run --privileged=true --net=host`，
  且 rpmbuild 走 `/root/rpmbuild`，属于权限越界，留在宿主机或 CI 执行；
- 宿主级 rpmbuild / hotpatch 链路（`lib/local-rpmbuild`、`lib/local-hotpatch`）不在容器内运行。

## 凭据注入（不写死、不入镜像）

宿主机设置以下环境变量后 Reopen in Container，`remoteEnv` 会将其转发进容器：

| 宿主机变量 | 容器内 | 用途 |
| --- | --- | --- |
| `CCB_ACCOUNT` | `ACCOUNT` | openEuler 社区账号（需鉴权命令必填） |
| `CCB_PASSWORD` | `PASSWORD` | 账号密码，仅存在于容器进程环境，不落盘 |
| `CCB_PUBLIC_KEY_URL` | `PUBLIC_KEY_URL` | 密码加密公钥地址（默认值已内置，一般无需设置） |
| `CCB_GATEWAY_IP` / `CCB_GATEWAY_PORT` | 写入 config.yaml | 可选：内网 EulerMaker 网关覆盖 |
| `CCB_REPOSITORIES_HOST/PORT/PROTOCOL` | 写入 config.yaml | 可选：内网 RPM 存储服务覆盖（`ccb download` 用） |
| `CCB_RESULT_HOST/PORT/PROTOCOL` | 写入 config.yaml | 可选：内网 job 日志服务覆盖（`ccb log` 用） |

ccb 源码支持 `ENV['ACCOUNT']` / `ENV['PASSWORD']` / `ENV['PUBLIC_KEY_URL']` 回退（见
`sbin/cli/ccb_common.rb`），因此密码不写入 `~/.config/cli/defaults/config.yaml`。未配置
凭据时，无法执行需要鉴权的命令。

## 配置与缓存

- 首次进入时 `post_install.sh` 将 `lib/default_config.yaml` 复制为
  `~/.config/cli/defaults/config.yaml`（容器内），并创建 `/usr/local/bin/ccb` 软链；
- bash 历史通过命名 volume 持久化（`ccb-history-*`），重建容器不丢；
- JWT 缓存 `~/.config/cli/jwt` 随容器重建清空，重新登录即可。

## 已知限制

- 远端 API 命令依赖 EulerMaker 网关可达（默认 `eulermaker.openeuler.openatom.cn`，可用
  `CCB_GATEWAY_IP` 覆盖为内网网关）；`ccb download` / `ccb log` 另依赖 `SRV_HTTP_*`
  地址，可用 `CCB_REPOSITORIES_HOST` / `CCB_RESULT_HOST` 覆盖；
- `lib/default_config.yaml` 中的 `DAILYBUILD_LOCAL/REMOTE` 内部地址仅 local-build 使用，本容器不涉及；
- 容器内不提供 docker（dinD），`local-build` / `local-rebuild` 无法在容器内使用。
