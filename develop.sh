#!/bin/bash

# 本地仓库目录
path="$HOME/blog"
# 部署目录
develop_path="$path/public"
# 部署文件
file_path="$path/public.tar.gz"

# 判断部署文件是否存在
if [ ! -f $file_path ]; then
    echo "$opt_file_path file does not exist"
    exit 0
fi

# 判断文件夹是否存在
if [ ! -x $develop_path ]; then
    mkdir -p $develop_path
fi

cd $HOME/blog

# 解压文件
tar -zxf $file_path -C $develop_path

echo 'Done.'
