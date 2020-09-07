---
title: "Arch 安装与配置"
date: 2019-09-11
tags: ["arch", "install"]
categories: ["arch"]
---

### 建立网络连接
安装程序会自动启动 `dhcpcd` ，有线连接可以直接使用，然后用 `ping` 命令检查连接是否成功。

```bash
# ping baidu.com
```
<!--more-->
如果使用的是无限网络连接，首先要先确定接口名称

```bash
# iw dev
```

输出类似如下（ 摘自官方 Wiki ）

```
phy#0
    Interface wlp8s0
        ifindex 3
        wdev 0x1
        addr 12:34:56:78:9a:bc
        type managed
        channel 1 (2412 MHz), width: 40 MHz, center1: 2422 MHz
```

假设接口名称为 wlp8s0 ，则使用下面命令连接无线网络

```bash
# wifi-menu wlp8s0
```

随后会提示要连接的无线网络，如果无线有密码还会在提示输入密码。
# 同步时间
```bash
# timedatectl set-ntp true
```
#### 硬件时间设置
使用本地时间可能会引起某些不可修复的 bug ，所以需要同步硬件时间
```bash
# hwclock --systohc
```
### 环境检查
#### UEFI/BIOS 检测
```bash
# ls /sys/firmware/efi/efivars
```
若该目录不存在，则 ArchISO 是以 BIOS/CSM 模式启动，否则是以 UEFI 模式启动。
### 分区
通常而言，UEFI 系统须使用 GPT 分区才能引导，BIOS 系统须使用 MBR 分区才能引导。

Arch Linux 要求至少一个分区分配给根目录 /。在 UEFI 系统上，需要一个 UEFI 系统分区。在 BIOS 系统上，则需要一个 BOOT 启动区

首先使用 `fdisk -l` 确定目标磁盘及目标分区。

假如该设备是/dev/sda，这时候你还可以通过如下命令查看该存储设备下已有的分区情况：

```bash
# fdisk -l /dev/sda
```

进入了fdisk分区工具里边，可以使用如下功能：

* m: 查看帮助
* n: 新建分区
* p: 查看已分区信息列表
* w: 保存本次分区操作结果并退出
* q: 不保存本次分区操作结果并退出

BIOS 模式：

* 只需要一个分区用于系统安装

UEFI 模式：
* 第一个分区用于系统引导
* 第二个分区用于系统安装

以下给出 UEFI 模式使用 `fdisk` 进行分区的示例

第一个分区 (引导分区)
```
输出 n 创建分区
Partition type 是分区类型，p是主分区，e是扩展分区，直接按回车键选择默认
Partition number 是分区编号，直接按回车键选择默认
First sector 是开始的部分，直接按回车键选择默认
Last sector 是结尾的部分，输入 +512M，按回车键
输入 t 准备将该分区更改为EFI类型分区，输入序号选择分区。输入 L 查看支持的类型，找到EFI类型前面对应的序号，这里的序号是 ef 。输入 ef 按回车键。
```
第二个分区（系统安装分区）
```
输出 n 创建分区
Partition type是分区类型，p是主分区，e是扩展分区，直接按回车键选择默认
Partition number是分区编号，直接按回车键选择默认
First sector是开始的部分，直接按回车键选择默认
Last sector是结尾的部分，直接按回车键选择默认
```
输入 `p` 查看分区列表

BIOS 模式请记住刚刚新建立的分区设备名，这里假如是 `/dev/sda1` ；UEFI 模式请记住刚刚新建立的两个分区的设备名，这里假如是 `/dev/sda1`（512M）和 `/dev/sda2`（249G）

### 格式化分区
```bash
# mkfs.fat -F32 /dev/sda1
# mkfs.ext4 /dev/sda2
```
### 挂载分区
```bash
# mount /dev/sda2 /mnt
# mkdir -p /mnt/boot/efi
# mount /dev/sda1 /mnt/boot/efi
```
### 安装基本系统
#### 编辑镜像站文件
由于镜像站文件中有太多国外网址，网速慢，所以在镜像站文件开头添加国内镜像站 

编辑 `/etc/pacman.d/mirrorlist` 文件，将国内源复制到前面。

在本机同步镜像源数据库：
```bash
# pacman -Syy
```
#### 安装基本系统
安装基本系统和自己需要的一些软件：
```bash
# pacstrap -i /mnt base base-devel
```
生成 fstab 文件：
```bash
# genfstab -U -p /mnt >> /mnt/etc/fstab
```
最好再执行以下命令检查一下：
```bash
# cat /mnt/etc/fastab
```
Change root 到系统：
```bash
# arch-chroot /mnt
```
设置主机名：
```bash
# echo <主机名> >> /etc/hostname
```
设置时区：
```bash
# ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```
编辑 `/etc/locale.gen` 文件，反注释需要的语言：
```
en_US.UTF-8 UTF-8 
zh_CN.UTF-8 UTF-8 
```
更新语言环境：
```bash
# locale-gen
```
设置系统 `locale` 偏好：
```bash
# echo LANG=en_US.UTF-8 >> /etc/locale.conf
```
设置密码
```bash
# passwd
```
配置 hosts
```bash
# vim /etc/hosts

127.0.0.1   localhost
::1         localhost
127.0.1.1   <主机名>.localdomain  <主机名> 
```

设置网络连接
```bash
# systemctl start dhcpcd.service    # 连接
# systemctl enable dhcpcd.service   # 开机启动自动连接
```
设置 openssh
```bash
# pacman -S openssh
# systemctl start sshd.service  # 连接
# systemctl enable sshd.service # 开机自动启动
```

#### 安装引导程序
BIOS 系统：
```bash
# pacman -S grub os-prober
# grub-install --target=i386-pc /dev/sda
# grub-mkconfig -o /boot/grub/grub.cfg
```
UEFI 系统：
```bash
# pacman -S grub efibootmgr
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Arch Linux" --recheck
# grub-mkconfig -o /boot/grub/grub.cfg
```
#### 完成安装
基本的 Arch Linux 系统已经安装好了，现在只需要退出 chroot ，卸载分区然后重启就行了。
```bash
# exit
# umount -R /mnt
# reboot
```
### 配置系统
新建用户和密码：
```bash
# useradd -m -G wheel -s /bin/bash tcrxaz
# passwd tcrxaz
```
使用户获得 `sudo` 权限：
```bash
# vim /etc/sudoers

反注释 %wheel ALL=(ALL) ALL
```
配置 archliuxcn 源：

在 `/etc/pacman.conf` 文件末尾添加两行
```
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
```
然后请安装 `archlinuxcn-keyring` 包以导入 GPG key。
```bash
# pacman -Syy
# pacman -S archlinuxcn-keyring
```
如果安装时报错 `ERROR: 5984EA8F3C could not be locally signed` 解决办法：
```bash
# rm -fr /etc/pacman.d/gnupg
# pacman-key --init
# pacman-key --populate archlinux
```

