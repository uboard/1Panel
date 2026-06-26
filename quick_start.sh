#!/bin/bash
set -e

REPO="uboard/1Panel"
PANEL_EDITION="cn"
EDITION_FILE=".selected_edition"

# 检测系统架构
osCheck=$(uname -a)
if [[ $osCheck =~ 'x86_64' ]]; then
    architecture="amd64"
elif [[ $osCheck =~ 'arm64' ]] || [[ $osCheck =~ 'aarch64' ]]; then
    architecture="arm64"
elif [[ $osCheck =~ 'armv7l' ]]; then
    architecture="armv7"
elif [[ $osCheck =~ 'ppc64le' ]]; then
    architecture="ppc64le"
elif [[ $osCheck =~ 's390x' ]]; then
    architecture="s390x"
elif [[ $osCheck =~ 'riscv64' ]]; then
    architecture="riscv64"
else
    echo "当前系统架构暂不支持，请参考官方文档选择受支持的系统与架构。"
    exit 1
fi

# 获取最新版本号
VERSION=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ -z "${VERSION}" ]]; then
    echo "获取最新版本失败，请检查网络连接或 API 限制。"
    exit 1
fi
echo "检测到最新版本: ${VERSION}"


# 设置下载变量
PACKAGE_FILE_NAME="1panel-${VERSION}-linux-${architecture}.tar.gz"
PACKAGE_DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${PACKAGE_FILE_NAME}"

# 检查下载逻辑
if [[ -f ${PACKAGE_FILE_NAME} ]]; then
    echo "检测到本地安装包，正在清理..."
    rm -f ${PACKAGE_FILE_NAME}
fi

echo "准备下载 1Panel ${VERSION} (架构: ${architecture})"
echo "下载地址: ${PACKAGE_DOWNLOAD_URL}"

# 下载安装包
curl -LOk ${PACKAGE_DOWNLOAD_URL}
if [[ ! -f ${PACKAGE_FILE_NAME} ]]; then
    echo "下载失败，请检查该版本是否存在对应的安装包文件。"
    exit 1
fi

# 解压与安装
tar zxf ${PACKAGE_FILE_NAME}
if [[ $? != 0 ]]; then
    echo "解压安装包失败，下载文件可能不完整或已损坏。"
    rm -f ${PACKAGE_FILE_NAME}
    exit 1
fi

# 进入解压目录
#TARGET_DIR="1panel-${VERSION}-linux-${architecture}"
TARGET_DIR=$(ls -d 1panel-* | grep -v ".tar.gz" | head -n 1)
if [[ -d "${TARGET_DIR}" ]]; then
    cd "${TARGET_DIR}" || exit 1
else
    echo "错误：解压后的目录结构不符合预期。"
    exit 1
fi

echo "$PANEL_EDITION" > "$EDITION_FILE"

echo "正在执行安装程序..."
/bin/bash install.sh

