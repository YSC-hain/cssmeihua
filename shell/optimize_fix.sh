#!/usr/bin/env bash

# 获取系统架构和内存信息
arch=$(getconf LONG_BIT)  # 系统位数
memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}') # 总内存 (KB)
memory_mb=$((memory_kb / 1024))  # 转换为 MB
memory_gb=$((memory_mb / 1024))  # 转换为 GB

# 动态计算优化参数
fs_file_max=$((memory_mb * 512))  # 文件描述符最大值
conntrack_max=$((memory_mb * 32))  # Conntrack 最大连接数
buckets=$((conntrack_max / 4))  # Conntrack 哈希桶大小
rmem_max=$((memory_mb * 1024 * 8))  # 网络接收缓冲区
wmem_max=$((memory_mb * 1024 * 8))  # 网络发送缓冲区
netdev_max_backlog=$((memory_mb * 256))  # 网络接口队列长度
somaxconn=$((memory_mb * 32))  # TCP 侦听队列长度
tcp_max_tw_buckets=$((memory_mb * 8))  # TIME-WAIT 连接数

# 检测系统发行版
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif grep -qi "debian\|raspbian" /etc/issue; then
    release="debian"
elif grep -qi "ubuntu" /etc/issue; then
    release="ubuntu"
elif grep -qi "centos\|red hat\|redhat" /etc/issue; then
    release="centos"
elif grep -qi "debian\|raspbian" /proc/version; then
    release="debian"
elif grep -qi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -qi "centos\|red hat\|redhat" /proc/version; then
    release="centos"
else
    echo "[错误] 不支持的操作系统！"
    exit 1
fi

# 更新系统
if [[ ${release} == "centos" ]]; then
    yum install -y epel-release
    yum update -y
else
    apt update -y
    apt autoremove --purge -y
fi

# 配置优化参数
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
ulimit -n $fs_file_max
ulimit -u $fs_file_max

echo "[信息] 优化完毕！"
exit 0
