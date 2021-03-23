#!/bin/bash
#
# https://github.com/like-ycy/linux-server-optimize

# Colors
red='\e[91m'
green='\e[92m'
yellow='\e[93m'

# 紫色
magenta='\e[95m'

# 青色
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
# 最后重启机器

StopFirewalld(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		systemctl stop firewalld
		systemctl disable firewalld
	fi

	# if [[ "$os" == "debian" && "$os_version" -ge 9 ]]; then
	# 	systemctl stop firewalld
	# 	systemctl disable firewalld
	# fi

	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		systemctl stop firewalld
		systemctl disable firewalld
	fi
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
	green "========  Selinux关闭成功  =========="
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
green "打开文件最大数和进程最大数目修改完毕"
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
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		""
	fi
	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		""
	fi
}

InstallTools(){
	if [[ "$os" == "ubuntu" && "$os_version" -ge 1804 ]]; then
		""
	fi
	if [[ "$os" == "centos" && "$os_version" -ge 7 ]]; then
		""
	fi
}





# 最后重启机器
# reboot






























