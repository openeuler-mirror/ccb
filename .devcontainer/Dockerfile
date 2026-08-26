# ccb devcontainer - openEuler 基础模板（最小范围）
# 范围边界（依据 openeuler-devcontainer 判定矩阵）：
#   - 做：统一 Ruby 版本 + 远端命令（select/create/update/build/log/ls/query/cancel/download/build-single）
#   - 不做：local-build / local-rebuild（依赖 dinD + --privileged + /root/rpmbuild，留在宿主机/CI）
# 资源要求：轻量 CLI，默认 2C/4G 即可，无特殊下限
#
# 使用说明：
#   1. Ruby 3.0（openEuler 22.03-lts-sp1 默认源，实际 3.0.3），满足 README 的 ruby 2.5+ 要求
#   2. rest-client 由 gem 安装，依赖 unf_ext 原生扩展，需 ruby-devel + gcc/gcc-c++/make
#   3. 内网镜像源（dnf / rubygems）通过 build.args（DNF_MIRROR / GEM_MIRROR）传入，
#      空值（默认）走公网 repo.openeuler.org / rubygems.org，不写死

ARG OPENEULER_IMAGE=openeuler/openeuler:22.03-lts-sp1
FROM ${OPENEULER_IMAGE}

ARG TZ=Asia/Shanghai
ENV TZ="${TZ}"

# 可选内网镜像：
#   DNF_MIRROR - openEuler 仓库镜像基址（须含 scheme，如 http://mirror.internal/openeuler），
#                非空时把 .repo 中 repo.openeuler.org 整体替换为该基址（baseurl/gpgkey 同步替换）
#   GEM_MIRROR - rubygems 镜像源地址（如 https://mirrors.tuna.tsinghua.edu.cn/rubygems/）
ARG DNF_MIRROR=
ENV DNF_MIRROR="${DNF_MIRROR}"
ARG GEM_MIRROR=
ENV GEM_MIRROR="${GEM_MIRROR}"

# Ruby CLI 工具链（openEuler dnf 包名）
RUN set -e; \
    if [ -n "${DNF_MIRROR}" ]; then \
      for f in /etc/yum.repos.d/*.repo; do \
        awk -v old_http="http://repo.openeuler.org" -v old_https="https://repo.openeuler.org" -v new="${DNF_MIRROR}" '{ idx = index($0, old_http); if (idx) { $0 = substr($0, 1, idx - 1) new substr($0, idx + length(old_http)) } else { idx = index($0, old_https); if (idx) { $0 = substr($0, 1, idx - 1) new substr($0, idx + length(old_https)) } } if ($0 ~ /^[[:space:]]*(metalink|mirrorlist)[[:space:]]*=/) { $0 = "#" $0 } print }' "${f}" >"${f}.tmp"; \
        mv "${f}.tmp" "${f}"; \
      done; \
    fi; \
    dnf update -y \
    && dnf install -y \
    git \
    curl \
    tar \
    unzip \
    sudo \
    vim \
    ca-certificates \
    tzdata \
    ruby \
    ruby-devel \
    rubygems \
    gcc \
    gcc-c++ \
    make \
    && test -e "/usr/share/zoneinfo/${TZ}" \
    && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && dnf clean all

# ccb 唯一第三方依赖（远端子命令均 require rest-client）
RUN set -e; \
    if [ -n "${GEM_MIRROR}" ]; then \
      gem sources --remove https://rubygems.org/ >/dev/null 2>&1 || true; \
      gem sources --add "${GEM_MIRROR}"; \
    fi; \
    gem install rest-client --no-document

# 创建开发用户（devcontainer remoteUser）
RUN useradd -m -s /bin/bash vscode && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscode && \
    chmod 440 /etc/sudoers.d/vscode && \
    mkdir -p /workspace /commandhistory && \
    chown -R vscode:vscode /workspace /commandhistory

WORKDIR /workspace
USER vscode
ENV SHELL=/bin/bash
ENV EDITOR=vim
