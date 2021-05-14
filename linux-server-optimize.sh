#!/bin/bash
#
# https://github.com/like-ycy/linux-server-optimize

# set env
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

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

# Detect Users
if [ $(whoami) != "root" ];then
	echo -e "\n哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n"
	exit 1;
fi
# [[ $(id -u) != 0 ]] && echo -e "\n哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit

# Detect bits
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
	echo -e "\n哈哈……要用 ${red}64 ${none}位系统的呀 ${yellow}~(^_^) ${none}\n"
fi

# Detect running the script with "sh" instead of "bash"
if readlink /proc/$$/exe | grep -q "sh"; then
	echo -e "\n这个脚本需要使用 ${red}bash ${none}运行，而不是 ${yellow}sh ${none}\n"
	exit
fi

# Detect Kernel
[[ $(uname -r | cut -d "." -f 1) -eq 2 ]] && echo -e "\n哎呀……当前系统内核版本过低，${red}请升级系统内核 ${none}\n" && exit

# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"

elif [[ -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
	group_name="nobody"

# This is annotation
:<<!
elif [[ -e /etc/debian_version ]]; then
 	os="debian"
 	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
 	group_name="nogroup"

elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
!

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

# This is annotation
:<<!
if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
	echo -e "此脚本需要 ${green}Debian 9${none} 或更高版本。\n"
	exit
fi
!

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
	echo -e "此脚本需要 ${green}Centos 7${none} 或更高版本。\n"
	exit
fi

# 关闭防火墙
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

# 关闭selinux
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

# 设置打开文件最大数
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

# 设置时区
TimeZone(){
	timedatectl set-timezone Asia/Shanghai
	timedatectl set-ntp true
	green "===================================="
	green "==========  时区修改完毕  ==========="
	green "===================================="
}

# 设置镜像源
Repo(){
	if [[ "$os" == "ubuntu" && "$os_version" == 1804 ]]; then
		mv /etc/apt/sources.list /etc/apt/sources.list.bak
	    wget -O /etc/apt/source.list https://github.com/like-ycy/linux-server-optimize/raw/main/sources1804.list
		apt-get update
	else
		mv /etc/apt/sources.list /etc/apt/sources.list.bak
		apt-get update

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

# 安装常用工具
InstallTools(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		apt install vim lrzsz curl wget net-tools bind-utils epel-release zip unzip git
	fi
	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		yum install -y lrzsz wget curl vim net-tools bind-utils epel-release zip unzip git
	fi
	green "===================================="
	blue "========== 常用工具安装完毕 =========="
	green "===================================="
}

# 内核优化
Kernel(){
	cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H-%M-%S"`
	wget -O /etc/sysctl.conf https://github.com/like-ycy/linux-server-optimize/raw/main/sysctl.conf
	source /etc/sysctl.conf
	green "===================================="
	blue "===========  内核参数完毕  ==========="
	green "===================================="
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