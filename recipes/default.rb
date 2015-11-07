# -*- coding: utf-8 -*-
#
# Cookbook Name:: objectStorage01
# Recipe:: default
#

#
# CloudFuseを動作させるために必要な
# パッケージのインストール
#
case node['platform']
when 'ubuntu','debian'
  execute 'apt-get update' do
    command 'apt-get update'
    action :run
  end

  %w{
    build-essential 
    libcurl4-openssl-dev 
    libxml2-dev 
    libssl-dev 
    libfuse-dev
  }.each do |pkgname|
    package "#{pkgname}" do
      action :install
    end
  end

when 'centos','redhat'
  execute 'yum update' do
    command 'yum update -y'
    action :run
  end

  %w{
    gcc
    make
    fuse-devel
    curl-devel
    libxml2-devel
    openssl-devel
    fuse
  }.each do |pkgname|
    package "#{pkgname}" do
      action :install
    end
  end
end


#
# cloudfuse の tar ファイルを対象サーバーへ転送する
# この tar ファイルは、以下のURLから取得したものです
# https://github.com/redbo/cloudfuse
#
filename = "cloudfuse.tgz"
file_checksum = "aea8ec51613c6a3f7ffd8cbed76b27d4fb0d028a796952e9f582b7e9c3ab2307"
work_dir = "/root/_cloudfuse_work"
cookbook_file "/root/#{filename}" do
  source "#{filename}"
  checksum "#{file_checksum}"
end


#
# cloudfuseを展開、ビルド、インストールします
#
script "install_cloudfuse" do
  interpreter "bash"
  user        "root"
  code <<-EOL
    install -d #{work_dir}
    tar zxvf /root/#{filename} -C #{work_dir}
    cd #{work_dir}/cloudfuse
    ./configure
    make
    make install
  EOL
end


#
# アトリビュートdefailt.rb や ロールからのオバーライドの設定値を
# ローカル変数にセットして、cloudfuseの認証ファイルに書き込む
#
os_username = node["objectstorage"]["username"]
os_api_key = node["objectstorage"]["apikey"]
os_authurl = node["objectstorage"]["authurl"]

file "/root/.cloudfuse" do
  owner "root"
  group "root"
  mode 0600
  config_file = "username=#{os_username}\n" \
    "api_key=#{os_api_key}\n" \
    "authurl=#{os_authurl}\n"
  content "#{config_file}}\n"
  action :create
end

#
# /etc/fstabの修正方法には、file で修正する方法が取れるが、
# しかし、複数のレシピを適用した場合、CHEFが定義する適用ルールに違反するため
# 動作しないケースが起こる。
# この問題を回避するため、rubyブロックから/etc/fstabに追加を加える
#
# fileで設定する場合のためコメント化して残しておく
#
#file '/etc/fstab' do
#  owner "root"
#  group "root"
#  mode 0644
#  not_if 'grep "^cloudfuse" /etc/fstab'
#  new_content = File.read( path )
#  p new_content
#  content "#{new_content}\n" \
#  "cloudfuse /os fuse auto,_netdev,defaults,gid=106,umask=007,allow_other    0 0\n"
#  action :create
#end
#
# Ruby block で /etc/fstab に変更設定
ruby_block 'adding_fstab_entry' do
  block do
    file = "/etc/fstab"
    line = "cloudfuse /os fuse auto,_netdev,defaults,gid=106,umask=007,allow_other    0 0\n"
    if (`grep "^cloudfuse" #{file}`.size == 0) then
    File::open(file, "a") do |f|
        f.write "#{line}"
      end
    end
  end
  action :run
end

#
# ディレクトリ作成
#
directory '/os' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

#
# オブジェクト・ストレージをブロック・ストレージとしてマウント
#
execute "/os" do
  command 'mount /os'
  ignore_failure true
end
