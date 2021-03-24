#!/bin/bash
#
# https://github.com/like-ycy/linux-server-optimize

# Colors
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

# Detect running the script with "sh" instead of "bash"
if readlink /proc/$$/exe | grep -q "sh"; then
	echo -e "\n这个脚本需要使用 ${red}bash ${none}运行，而不是 ${yellow}sh ${none}\n"
	exit
fi

# Detect Users
[[ $(id -u) != 0 ]] && echo -e "\n哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit

# Detect Kernel
[[ $(uname -r | cut -d "." -f 1) -eq 2 ]] && echo -e "\n哎呀……当前系统内核版本过低，${red}请升级系统内核 ${none}\n" && exit

# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
# elif [[ -e /etc/debian_version ]]; then
# 	os="debian"
# 	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
# 	group_name="nogroup"
elif [[ -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
	group_name="nobody"
# elif [[ -e /etc/fedora-release ]]; then
# 	os="fedora"
# 	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
# 	group_name="nobody"
else
	echo -e "
	哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

	备注: 仅支持 ${green}Ubuntu 18+ / CentOS 7+ ${none}系统
	" && exit 1
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo -e "\n此脚本需要 ${green}Ubuntu 18.04${none} 或更高版本。\n"
	exit
fi

# if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
# 	echo -e "此脚本需要 ${green}Debian 9${none} 或更高版本。\n"
# 	exit
# fi

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
	echo -e "此脚本需要 ${green}Centos 7${none} 或更高版本。\n"
	exit
fi

StopFirewalld(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		systemctl stop ufw
		systemctl disable ufw
	fi

	# if [[ "$os" == "debian" && "$os_version" -ge 9 ]]; then
	# 	systemctl stop firewalld
	# 	systemctl disable firewalld
	# fi

	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		systemctl stop firewalld
		systemctl disable firewalld
	fi
	green "===================================="
	blue "==========  防火墙关闭成功  =========="
	green "===================================="
}

StopSelinux(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		""
	fi
	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
		if [ "$CHECK" == "SELINUX=enforcing" ]; then
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
		fi

		if [ "$CHECK" == "SELINUX=permissive" ]; then
			sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
		fi
	fi
	green "===================================="
	blue "========  Selinux关闭成功  =========="
	green "===================================="
}

OpenFiles(){
cp /etc/security/limits.conf /etc/security/limits.conf.`date +"%Y-%m-%d_%H-%M-%S"`
if [[ $? -ne 1 ]] ; then
cat <<EOF >> /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
* soft nproc  65535
* hard nproc  65535
EOF
fi
green "===================================="
blue "打开文件最大数和进程最大数目修改完毕"
green "===================================="
}

TimeZone(){
	timedatectl  set-timezone Asia/Shanghai
	timedatectl set-ntp true
	green "===================================="
	green "==========  时区修改完毕  ==========="
	green "===================================="
}

Repo(){
	if [[ "$os" == "ubuntu" && "$os_version" == 1804 ]]; then
		cp /etc/apt/sources.list /etc/apt/sources.list.bak
	else
		cp /etc/apt/sources.list /etc/apt/sources.list.bak
	fi
	if [[ "$os" == "centos" && "$os_version" == 7 ]]; then
		yum install wget -y
		mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		yum clean all
		yum makecache
	else
		dnf install wget -y
		cd /etc/yum.repos.d/
		for name in `ls *.repo`; do mv $name ${name%}.bak; done
		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
		yum clean all
		yum makecache
	fi
	green "===================================="
	blue "==========  镜像源修改完毕  =========="
	green "===================================="
}

InstallTools(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then

	fi
	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		yum install -y lrzsz wget curl vim net-tools bind-utils epel-release
	fi
}


Kernel(){
cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H-%M-%S"`
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
}

start_menu(){
    clear
    green " ===================================="
    green "       Linux系统优化脚本              "
    green " ===================================="
    echo
    green " 1. 关闭防火墙和Selinux"
    green " 2. 修改打开文件最大数"
    green " 3. 修改时区"
    green " 4. 修改镜像源"
	green " 5. 安装工具"
	green " 6. 内核优化"
	green " 7. 小孩子才做选择，我全都要!"
    blue " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    StopFirewalld
	StopSelinux
    ;;
    2)
    OpenFiles
    ;;
    3)
    TimeZone
    ;;
    4)
    Repo
    ;;
	5)
	InstallTools
	;;
	6)
	Kernel
	;;
	7)
	StopFirewalld
	StopSelinux
	OpenFiles
	TimeZone
	Repo
	InstallTools
	Kernel
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu

# 最后重启机器
red " ===================================="
blue "       都优化完了，要重启机器吗        "
red " ===================================="
echo
read -p "是否现在重启 ?请输入 [Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
	echo -e "即将重启..."
	reboot
fi