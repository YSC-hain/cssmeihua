#!/usr/bin/env bash

backup_dir="/etc/backup_tcp_tuning"

# 备份配置文件
backup_config() {
    mkdir -p "$backup_dir"
    cp /etc/sysctl.conf "$backup_dir/sysctl.conf.bak"
    cp /etc/security/limits.conf "$backup_dir/limits.conf.bak"
    cp /etc/systemd/journald.conf "$backup_dir/journald.conf.bak"
    echo "[信息] 配置文件已备份到 $backup_dir"
}

# 恢复备份的源函数
recovery_cof() {
    if [[ -f "$backup_dir/sysctl.conf.bak" ]]; then
        cp "$backup_dir/sysctl.conf.bak" /etc/sysctl.conf
        cp "$backup_dir/limits.conf.bak" /etc/security/limits.conf
        cp "$backup_dir/journald.conf.bak" /etc/systemd/journald.conf
    else
        echo -e "${RED}开始备份${NC}"
    fi
}

# 恢复原始配置
restore_config() {
    if [[ -f "$backup_dir/sysctl.conf.bak" ]]; then
        cp "$backup_dir/sysctl.conf.bak" /etc/sysctl.conf
        cp "$backup_dir/limits.conf.bak" /etc/security/limits.conf
        cp "$backup_dir/journald.conf.bak" /etc/systemd/journald.conf
        sysctl --system
        echo "[信息] 原始配置已恢复"
    else
        echo "[错误] 备份文件不存在，无法恢复"
    fi
    exit 0
}

# 退出脚本
exit_script() {
    echo "[信息] 脚本已退出"
    exit 0
}

# 配置优化参数
optimize_system() {
    # 获取系统架构和内存信息
    memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    memory_mb=$((memory_kb / 1024))

    # 计算优化参数
    fs_file_max=$((memory_mb * 512))
    conntrack_max=$((memory_mb * 32))
    buckets=$((conntrack_max / 4))
    rmem_max=$((memory_mb * 1024 * 8))
    wmem_max=$((memory_mb * 1024 * 8))
    netdev_max_backlog=$((memory_mb * 256))
    somaxconn=$((memory_mb * 32))
    tcp_max_tw_buckets=$((memory_mb * 8))

    # 配置 sysctl
    cat > /etc/sysctl.conf << EOF
fs.file-max = $fs_file_max

# 增强网络缓冲区
net.core.rmem_max = $rmem_max
net.core.wmem_max = $wmem_max
net.core.netdev_max_backlog = $netdev_max_backlog
net.core.somaxconn = $somaxconn

# 启用 IP 转发
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1

# TCP 连接优化
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_max_tw_buckets = $tcp_max_tw_buckets
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_adv_win_scale = 2

# NAT 连接追踪优化
net.netfilter.nf_conntrack_max = $conntrack_max
net.netfilter.nf_conntrack_buckets = $buckets
net.netfilter.nf_conntrack_tcp_timeout_established = 600
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 30
net.netfilter.nf_conntrack_tcp_be_liberal = 1

# 默认使用 fq 调度器
net.core.default_qdisc = fq

# 其他优化
vm.swappiness = 0
vm.overcommit_memory = 1
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
EOF

    # 配置文件句柄和进程限制
    cat > /etc/security/limits.conf << EOF
* soft nofile $fs_file_max
* hard nofile $fs_file_max
* soft nproc $fs_file_max
* hard nproc $fs_file_max
root soft nofile $fs_file_max
root hard nofile $fs_file_max
root soft nproc $fs_file_max
root hard nproc $fs_file_max
EOF

    # 配置 systemd 日志限制
    cat > /etc/systemd/journald.conf << EOF
[Journal]
SystemMaxUse=384M
SystemMaxFileSize=128M
ForwardToSyslog=no
EOF

    # 应用优化参数
    sysctl --system

    echo "[信息] TCP 调优完成！"
    exit 0
}

echo "请选择操作："
echo "1. TCP 调优"
echo "2. 恢复原始配置"
echo "0. 退出脚本"
read -rp "请输入选项（1/2/0）: " option

case "$option" in
    1)
        recovery_cof
        backup_config
        optimize_system
        ;;
    2)
        restore_config
        ;;
    0)
        exit_script
        ;;
    *)
        echo "[错误] 请输入有效的选项！"
        exit 1
        ;;
esac
