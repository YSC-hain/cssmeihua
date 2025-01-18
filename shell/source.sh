#!/bin/bash

# 定义颜色变量
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

cop_info(){
clear
echo -e "${GREEN}######################################
#         ${RED}Debian换源一键脚本         ${GREEN}#
#             作者: ${YELLOW}末晨             ${GREEN}#
#         ${GREEN}https://blog.mochen.one    ${GREEN}#
######################################${NC}"
echo
}

# 检查系统是否为 Debian
if ! grep -qi "debian" /etc/os-release; then
    echo -e "${RED}本脚本仅支持 Debian 系统，请在 Debian 系统上运行。${NC}"
    exit 1
fi

# 检查用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}该脚本必须以root身份运行。${NC}"
    exit 1
fi

# 检查是否安装 curl，如果没有安装，则安装 curl
check_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}未检测到 curl，正在安装 curl...${NC}"
        apt update
        apt install -y curl
        if [ $? -ne 0 ]; then
            echo -e "${RED}安装 curl 失败，请手动安装后重新运行脚本。${NC}"
            exit 1
        fi
    fi
}

# 备份现有的sources.list
backup_sources() {
    backup_path="/etc/apt/sources.list.backup"
    cp /etc/apt/sources.list "$backup_path"
    echo -e "${GREEN}源列表已成功备份至：${backup_path}${NC}"
}

# 恢复备份的源函数
recovery_sources() {
    if [ -f /etc/apt/sources.list.backup ]; then
        cp /etc/apt/sources.list.backup /etc/apt/sources.list
        echo -e "${GREEN}正在保存最开始的sources.list。${NC}"
    else
        echo -e "${RED}开始备份${NC}"
    fi
}

# 更新为官方Debian镜像源的函数
update_sources() {
    check_curl
    recovery_sources
    backup_sources

    # 检查镜像源是否可用
    if ! curl -s --head https://deb.debian.org/debian/ | head -n 1 | grep "200" > /dev/null; then
        echo -e "${RED}官方Debian镜像源不可用。请稍后再试或选择其他镜像源。${NC}"
        exit 1
    fi

    # 检查系统版本
    VERSION=$(grep -oE 'VERSION="[0-9]+' /etc/os-release | cut -d '"' -f2)
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}无法检测系统版本。请确认操作系统是否为Debian并重试。${NC}"
        exit 1
    fi

    # 定义对应版本的源
    if [[ "$VERSION" == "10" ]]; then
        SOURCES_LIST=$(cat << EOF
deb http://deb.debian.org/debian/ buster main contrib non-free
deb-src http://deb.debian.org/debian/ buster main contrib non-free

deb http://deb.debian.org/debian/ buster-updates main contrib non-free
deb-src http://deb.debian.org/debian/ buster-updates main contrib non-free

deb http://deb.debian.org/debian/ buster-backports main contrib non-free
deb-src http://deb.debian.org/debian/ buster-backports main contrib non-free

deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "11" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://deb.debian.org/debian/ bullseye main contrib non-free
deb-src https://deb.debian.org/debian/ bullseye main contrib non-free

deb https://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src https://deb.debian.org/debian/ bullseye-updates main contrib non-free

deb https://deb.debian.org/debian/ bullseye-backports main contrib non-free
deb-src https://deb.debian.org/debian/ bullseye-backports main contrib non-free

deb https://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src https://deb.debian.org/debian-security/ bullseye-security main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "12" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://deb.debian.org/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
        )
    else
        echo -e "${RED}不支持的Debian版本：$VERSION。请手动配置源。${NC}"
        exit 1
    fi

    # 更新 sources.list 文件
    echo "$SOURCES_LIST" > /etc/apt/sources.list
    echo -e "${GREEN}Debian源已成功更新为官方镜像（版本：Debian $VERSION）。${NC}"
}

# 更新为清华镜像的函数
update_tsinghua_mirrors_sources() {
    check_curl
    recovery_sources
    backup_sources

    # 检查清华镜像源是否可用
    if ! curl -s --head https://mirrors.tuna.tsinghua.edu.cn/debian/ | head -n 1 | grep "200" > /dev/null; then
        echo -e "${RED}清华镜像源不可用。请稍后再试或选择其他镜像源。${NC}"
        exit 1
    fi

    # 检查系统版本
    VERSION=$(grep -oE 'VERSION="[0-9]+' /etc/os-release | cut -d '"' -f2)
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}无法检测系统版本。请确认操作系统是否为Debian并重试。${NC}"
        exit 1
    fi

    # 定义对应版本的源
    if [[ "$VERSION" == "10" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ buster/updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security/ buster/updates main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "11" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bullseye-security main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bullseye-security main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "12" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
        )
    else
        echo -e "${RED}不支持的Debian版本：$VERSION。请手动配置源。${NC}"
        exit 1
    fi

    # 更新 sources.list 文件
    echo "$SOURCES_LIST" > /etc/apt/sources.list
    echo -e "${GREEN}Debian源已成功更新为使用清华镜像（版本：Debian $VERSION）。${NC}"
}

# 更新为中科大镜像的函数
update_ustc_mirrors_sources() {
    check_curl
    recovery_sources
    backup_sources

    # 检查中科大镜像源是否可用
    if ! curl -s --head https://mirrors.ustc.edu.cn/debian/ | head -n 1 | grep "200" > /dev/null; then
        echo -e "${RED}中科大镜像源不可用。请稍后再试或选择其他镜像源。${NC}"
        exit 1
    fi

    # 检查系统版本
    VERSION=$(grep -oE 'VERSION="[0-9]+' /etc/os-release | cut -d '"' -f2)
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}无法检测系统版本。请确认操作系统是否为Debian并重试。${NC}"
        exit 1
    fi

    # 根据版本设置源
    if [[ "$VERSION" == "10" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.ustc.edu.cn/debian/ buster main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ buster main contrib non-free

deb https://mirrors.ustc.edu.cn/debian/ buster-updates main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ buster-updates main contrib non-free

deb https://mirrors.ustc.edu.cn/debian/ buster-backports main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ buster-backports main contrib non-free

deb https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "11" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free

deb https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free

deb https://mirrors.ustc.edu.cn/debian-security/ bullseye-security main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian-security/ bullseye-security main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "12" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
        )
    else
        echo -e "${RED}不支持的Debian版本：$VERSION。请手动配置源。${NC}"
        exit 1
    fi

    # 更新 sources.list 文件
    echo "$SOURCES_LIST" > /etc/apt/sources.list
    echo -e "${GREEN}Debian源已成功更新为使用中科大镜像（版本：Debian $VERSION）。${NC}"
}

# 更新为腾讯云镜像的函数
update_tencent_mirrors_sources() {
    check_curl
    recovery_sources
    backup_sources

    # 检查腾讯云镜像源是否可用
    if ! curl -s --head https://mirrors.cloud.tencent.com/debian/ | head -n 1 | grep "200" > /dev/null; then
        echo -e "${RED}腾讯云镜像源不可用。请稍后再试或选择其他镜像源。${NC}"
        exit 1
    fi

    # 检查系统版本
    VERSION=$(grep -oE 'VERSION="[0-9]+' /etc/os-release | cut -d '"' -f2)
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}无法检测系统版本。请确认操作系统是否为Debian并重试。${NC}"
        exit 1
    fi

    # 根据版本设置源
    if [[ "$VERSION" == "10" ]]; then
        SOURCES_LIST=$(cat << EOF
deb http://mirrors.tencentyun.com/debian/ buster main contrib non-free
deb-src http://mirrors.tencentyun.com/debian/ buster main contrib non-free

deb http://mirrors.tencentyun.com/debian/ buster-updates main contrib non-free
deb-src http://mirrors.tencentyun.com/debian/ buster-updates main contrib non-free

deb http://mirrors.tencentyun.com/debian/ buster-backports main contrib non-free
deb-src http://mirrors.tencentyun.com/debian/ buster-backports main contrib non-free

deb http://mirrors.tencentyun.com/debian-security/ buster/updates main contrib non-free
deb-src http://mirrors.tencentyun.com/debian-security/ buster/updates main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "11" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.cloud.tencent.com/debian/ bullseye main contrib non-free
deb-src https://mirrors.cloud.tencent.com/debian/ bullseye main contrib non-free

deb https://mirrors.cloud.tencent.com/debian/ bullseye-updates main contrib non-free
deb-src https://mirrors.cloud.tencent.com/debian/ bullseye-updates main contrib non-free

deb https://mirrors.cloud.tencent.com/debian/ bullseye-backports main contrib non-free
deb-src https://mirrors.cloud.tencent.com/debian/ bullseye-backports main contrib non-free

deb https://mirrors.cloud.tencent.com/debian-security/ bullseye-security main contrib non-free
deb-src https://mirrors.cloud.tencent.com/debian-security/ bullseye-security main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "12" ]]; then
        echo -e "${YELLOW}检测到系统为 Debian 12，是否运行在腾讯云机器上？(y/n): ${NC}"
        read -r IS_TENCENT_MACHINE
        if [[ "$IS_TENCENT_MACHINE" == "y" ]]; then
            SOURCES_LIST=$(cat << EOF
deb http://mirrors.tencentyun.com/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://mirrors.tencentyun.com/debian/ bookworm main contrib non-free non-free-firmware

deb http://mirrors.tencentyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://mirrors.tencentyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware

deb http://mirrors.tencentyun.com/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://mirrors.tencentyun.com/debian/ bookworm-backports main contrib non-free non-free-firmware

deb http://mirrors.tencentyun.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src http://mirrors.tencentyun.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
            )
        else
            SOURCES_LIST=$(cat << EOF
deb https://mirrors.cloud.tencent.com/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://mirrors.cloud.tencent.com/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.cloud.tencent.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://mirrors.cloud.tencent.com/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.cloud.tencent.com/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src https://mirrors.cloud.tencent.com/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.cloud.tencent.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src https://mirrors.cloud.tencent.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
            )
        fi
    else
        echo -e "${RED}不支持的Debian版本：$VERSION。请手动配置源。${NC}"
        exit 1
    fi

    # 更新 sources.list 文件
    echo "$SOURCES_LIST" > /etc/apt/sources.list
    echo -e "${GREEN}Debian源已成功更新为使用腾讯云镜像（版本：Debian $VERSION）。${NC}"
}

# 更新为阿里云镜像的函数
update_aliyun_mirrors_sources() {
    check_curl
    recovery_sources
    backup_sources

    # 检查阿里云镜像源是否可用
    if ! curl -s --head https://mirrors.aliyun.com/debian/ | head -n 1 | grep "200" > /dev/null; then
        echo -e "${RED}阿里云镜像源不可用。请稍后再试或选择其他镜像源。${NC}"
        exit 1
    fi

    # 检查系统版本
    VERSION=$(grep -oE 'VERSION="[0-9]+' /etc/os-release | cut -d '"' -f2)
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}无法检测系统版本。请确认操作系统是否为Debian并重试。${NC}"
        exit 1
    fi

    # 根据版本设置源
    if [[ "$VERSION" == "10" ]]; then
        SOURCES_LIST=$(cat << EOF
deb http://mirrors.aliyun.com/debian/ buster main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free

deb http://mirrors.aliyun.com/debian-security/ buster/updates main
deb-src http://mirrors.aliyun.com/debian-security/ buster/updates main
EOF
        )
    elif [[ "$VERSION" == "11" ]]; then
        SOURCES_LIST=$(cat << EOF
deb https://mirrors.aliyun.com/debian/ bullseye main contrib non-free
deb-src https://mirrors.aliyun.com/debian/ bullseye main contrib non-free

deb https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free
deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free

deb https://mirrors.aliyun.com/debian/ bullseye-backports main contrib non-free
deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main contrib non-free

deb https://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free
deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free
EOF
        )
    elif [[ "$VERSION" == "12" ]]; then
        echo -e "${YELLOW}检测到系统为 Debian 12，是否运行在阿里云机器上？(y/n): ${NC}"
        read -r IS_TENCENT_MACHINE
        if [[ "$IS_TENCENT_MACHINE" == "y" ]]; then
            SOURCES_LIST=$(cat << EOF
deb http://mirrors.cloud.aliyuncs.com/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://mirrors.cloud.aliyuncs.com/debian/ bookworm main contrib non-free non-free-firmware

deb http://mirrors.cloud.aliyuncs.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://mirrors.cloud.aliyuncs.com/debian/ bookworm-updates main contrib non-free non-free-firmware

deb http://mirrors.cloud.aliyuncs.com/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://mirrors.cloud.aliyuncs.com/debian/ bookworm-backports main contrib non-free non-free-firmware

deb http://mirrors.cloud.aliyuncs.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src http://mirrors.cloud.aliyuncs.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
            )
        else
            SOURCES_LIST=$(cat << EOF
deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.aliyun.com/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src https://mirrors.aliyun.com/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.aliyun.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src https://mirrors.aliyun.com/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
            )
        fi
    else
        echo -e "${RED}不支持的Debian版本：$VERSION。请手动配置源。${NC}"
        exit 1
    fi

    # 更新 sources.list 文件
    echo "$SOURCES_LIST" > /etc/apt/sources.list
    echo -e "${GREEN}Debian源已成功更新为使用阿里云镜像（版本：Debian $VERSION）。${NC}"
}

# 恢复备份的源函数
restore_sources() {
    if [ -f /etc/apt/sources.list.backup ]; then
        cp /etc/apt/sources.list.backup /etc/apt/sources.list
        echo -e "${GREEN}已成功恢复为备份的源。${NC}"
    else
        echo -e "${RED}无法检测到备份文件，请检查是否有备份。${NC}"
    fi
}

cop_info

echo "请选择一个选项："
echo "0: 退出"
echo "1: 使用官方Debian镜像源"
echo "2: 使用清华镜像源"
echo "3: 使用中科大镜像源"
echo "4: 使用腾讯云镜像源"
echo "5: 使用阿里云镜像源"
echo "6: 恢复备份的源"
read -p "请输入您的选择：" choice

# 检查用户输入并相应地更新源列表
case "$choice" in
    0)
        echo -e "${RED}退出，未更改源。${NC}"
        exit 0
        ;;
    1)
        update_sources
        ;;
    2)
        update_tsinghua_mirrors_sources
        ;;
    3)
        update_ustc_mirrors_sources
        ;;
    4)
        update_tencent_mirrors_sources
        ;;
    5)
        update_aliyun_mirrors_sources
        ;;
    6)
        restore_sources
        ;;
    *)
        echo -e "${RED}无效的选项，请选择0、1、2、3、4、5或6。${NC}"
        exit 1
        ;;
esac
