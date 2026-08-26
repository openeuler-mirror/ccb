# ccb devcontainer - openEuler 基础模板（最小范围）
# 范围边界（依据 openeuler-devcontainer 判定矩阵）：
#   - 做：统一 Ruby 版本 + 远端命令（select/create/update/build/log/ls/query/cancel/download/build-single）
#   - 不做：local-build / local-rebuild（依赖 dinD + --privileged + /root/rpmbuild，留在宿主机/CI）
# 资源要求：轻量 CLI，默认 2C/4G 即可，无特殊下限
#
# 使用说明：
#   1. Ruby 3.0（openEuler 22.03-lts-sp1 默认源，实际 3.0.3），满足 README 的 ruby 2.5+ 要求
#   2. rest-client 由 gem 安装，依赖 unf_ext 原生扩展，需 ruby-devel + gcc/gcc-c++/make
#   3. 内网镜像源（dnf / rubygems）用 ARG/ENV 传入，不写死

ARG OPENEULER_IMAGE=openeuler/openeuler:22.03-lts-sp1
FROM ${OPENEULER_IMAGE}

ARG TZ=Asia/Shanghai
ENV TZ="${TZ}"

# Ruby CLI 工具链（openEuler dnf 包名）
RUN dnf update -y && dnf install -y \
    git \
    curl \
    tar \
    unzip \
    sudo \
    vim \
    ca-certificates \
    ruby \
    ruby-devel \
    rubygems \
    gcc \
    gcc-c++ \
    make \
    && dnf clean all

# ccb 唯一第三方依赖（远端子命令均 require rest-client）
RUN gem install rest-client --no-document

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
