#!/bin/bash

# 判断系统发行版本，命令的不同及文件路径的不同
# 关闭防火墙
# 关闭selinux
# 升级内核
# 修改主机名
# 修改文件打开数
# 修改内核参数
# 修改时区
# 修改yum源
# 安装必要工具lrzsz wget curl vim net-tools bind-utils epel-release
# k8s的要关闭swap分区
# 添加hosts文件

echo -e "\033[32m+-------------------------------------------------------+\033[0m"
echo -e "\033[32m|             Welcome to System init                    |\033[0m"
echo -e "\033[32m+-------------------------------------------------------+\033[0m"
format(){
          sleep 5
          echo -e "\033[1;32m ----------------- Finished ----------------- \033[0m"
          echo "  "
}
##############################Set env###########################################
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [[ "$(whoami)" != "root" ]]; then
    echo "Please run this script as root."
    exit 1;
fi

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
	echo "抱歉, 此脚本不支持32位系统, 请使用64位系统!";
fi

##############################Set Open File#####################################
openFiles(){
        echo "------------Set Open File 65535-------------------"
        \cp /etc/security/limits.conf /etc/security/limits.conf.`date +"%Y-%m-%d_%H-%M-%S"`
if [[ $? -ne 1 ]] ; then
cat <<EOF >> /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
* soft nproc  65535
* hard nproc  65535
EOF
fi
        echo "调整最大打开系统文件个数成功！（修改后重新登录生效）"
        format
}

###########################Kernel optimization###################################
optimizationKernel(){
        echo "Kernel optimization----->"
        \cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H-%M-%S"`
if [[ $? -ne 1 ]] ; then
cat <<EOF >>/etc/sysctl.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
kernel.shmmax=15461882265
kernel.shmall=3774873
kernel.msgmax=65535
kernel.msgmnb=65535
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 1024 65000
fs.file-max = 131072
vm.max_map_count=262144
EOF
fi
/sbin/sysctl -p
format
}
openFiles
optimizationKernel
