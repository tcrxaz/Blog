---
title: "在 Arch 中使用 Systemd 挂载文件系统"
date: 2019-09-12
tags: ["arch", "systemd"]
categories: ["arch"]
---

为什么使用 Systemd 来挂载文件系统而不使用 fstab？使用 fstab 的时候如果设备被移除会导致系统启动失败，无法进入系统（只能进入临时修复系统），Systemd 则没有这个问题。
<!--more-->

# 查看磁盘 UUID
```bash
# lsblk -f

NAME   FSTYPE LABEL UUID                                 MOUNTPOINT
vda
└─vda1 ext4         1114fe9e-2309-4580-b183-d778e6d97397 /
```

# systemd.mount
mount 单元的名称必须根据其封装的文件系统挂载点路径命名。例如 /home/lennart 挂载点对应的单元名称必须是 home-lennart.mount。如果路径中含有特殊字符，则需要将所有其他非ASCII字母与数字替换为 C 风格的 "\x??" 转义序列。建议使用 systemd-escape 工具在单元的名字与路径之间相互转换。
## systemd-escape 简单使用

``` bash
# systemd-escape -p --suffix=mount "/home/Disk/disk_1/"

home-Disk-disk_1.mount
```

## systemd.mount 编写
以上面查询出来的硬盘为例

```bash
# vim /usr/lib/systemd/system/home-Disk-disk_1.mount

[Unit]
Description=Mount Drive

[Mount]
What=/dev/disk/by-uuid/fe3ea09a-3bbd-473d-af69-994535ff8555
Where=/home/Disk/disk_1
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target

```
## systemd 启动与开机自动挂载
``` bash
# systemctl start home-Disk-disk_1.mount
# systemctl enable home-Disk-disk_1.mount
```
