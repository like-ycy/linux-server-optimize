## linux系统优化脚本

此脚本目前只支持CentOS7+ \ Ubuntu 18+

## 脚本功能
- 关闭防火墙
- 关闭selinux
- 设置文件打开最大数
- 修改时区为上海
- 修改镜像源为阿里镜像源
- 安装工具
- 内核参数优化
- 最后重启机器

## 待选择添加
- 是否需要关闭1、2、3、4这些小的优化步骤，直接一个脚本全执行
- 关闭swap分区
#### 目前脚本问题：
- 1、1,2,3,4小步骤执行完之后不会重新回到脚本选择项
## 使用方法
```bash
# 1、克隆项目
git clone https://github.com/like-ycy/linux-server-optimize.git

# 2、运行脚本
cd linux-server-optimize
chmod +x linux-server-optimize.sh
bash linux-server-optimize.sh
```