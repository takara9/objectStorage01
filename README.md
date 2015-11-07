objectStorage01 Cookbook
========================
オブジェクトストレージをブロックストレージとしてマウント出来る様に、
CloudFuse をインストールして、fstabを設定する

このCookbookに、Cloudfuse が含まれていますが、最新版と入れ替えるには、
https://github.com/redbo/cloudfuse から取得して入れ替えてください。

Requirements
------------

- Chef 12.x 以上
- Ubuntu 14.04 LTS 64bit
- CentOS 6.x 64bit
- CentOS 7.x 64bit


Attributes
----------
オブジェクト・ストレージをアクセスするために必要な認証情報を
SOFTLAYERのカスタマーポータルにログインして取得して、Attributes に設定します。

#### objectStorage01::default
<table>
  <tr>
    <th>キー</th>
    <th>型</th>
    <th>説明</th>
    <th>デフォルト値</th>
  </tr>
  <tr>
    <td>["objectstorage"]["username"]</td>
    <td>文字列</td>
    <td>Object Storage のユーザID</td>
    <td>なし</td>
  </tr>
  <tr>
    <td>["objectstorage"]["apikey"]</td>
    <td>文字列</td>
    <td>Object Storage のAPI KEY</td>
    <td>なし</td>
  </tr>

  <tr>
    <td>["objectstorage"]["authurl"]</td>
    <td>文字列</td>
    <td>認証URLアドレス</td>
    <td>なし</td>
  </tr>
</table>


使用法(Usage)
-----

#### Knife Solo で利用する方法 
レポジトリ用のディレクトリを作成して初期化する。

```
$ mkdir chef-solo-repo
$ cd chef-solo-repo
$ knife solo init .
```
site-cookbooksの下にクックブックをクローンする

```
$ cd site-cookbooks/
$ git clone https://github.com/takara9/objectStorage01 
```
一応、GitHubから落ちてきているか確認

```
$ pwd
/home/chef/chef-solo-repo/site-cookbooks
$ ls
objectStorage01
```
attributes/default.rb を編集して認証情報をセットした後、
hostnameのインスタンスに、クックブックを適用する

```
$ cd /home/chef/chef-solo-repo
$ knife solo bootstrap root@hostname -i sshkey -r 'recipe[objectStorage01]'
```

#### Knife Server/WorkStation から利用する方法
Chef WorkStaion のリポジトリに移動して、クックブックをクローンする。

```
$ pwd
/home/chef/chef-repo/cookbooks
$ git clone https://github.com/takara9/objectStorage01
```
クックブックをCHEFサーバーへアップロードする

```
$ knife cookbook upload objectStorage01 
Uploading objectStorage01 [0.1.0]
Uploaded 1 cookbook.
```
ロールを作成して、オブジェクトストレージの認証情報のAttributeを上書きする様にします。

```
$ knife role create webserver
```
先に作成したロールを指定して、CHEFクライアントをインストールします。

```
$ knife bootstrap hostname -i sshkey -N web01 -r 'role[webserver]'
```



#### 適用後のサーバーの状態

```
root@web02:~# df -m
Filesystem     1M-blocks  Used Available Use% Mounted on
/dev/xvda2         24829  1410     22153   6% /
none                   1     0         1   0% /sys/fs/cgroup
udev                 486     1       486   1% /dev
tmpfs                 99     1        99   1% /run
none                   5     0         5   0% /run/lock
none                 495     0       495   0% /run/shm
none                 100     0       100   0% /run/user
/dev/xvda1           232    18       202   9% /boot
cloudfuse        8388608     0   8388608   0% /os
```


#### objectStorage01::default

nodeファイルに定義する場合、run_listにrecipe[objectStorage01]を加えます。

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[objectStorage01]"
  ]
}
```

#### attributes/default.rb

attributesにオブジェクト・ストレージの認証情報をセットする場合、SoftLayerのカスタマーポータルから、認証情報は取得します。

```
default["objectstorage"]["username"]="*************:*********"
default["objectstorage"]["apikey"]="****************************************************************"
default["objectstorage"]["authurl"]="https://tok02.objectstorage.softlayer.net/auth/v1.0/"

```

#### role
roleのオーバーライドに設定する場合の例です。

```
{
  "name": "webserver",
  "description": "",
  "json_class": "Chef::Role",
  "default_attributes": {

  },
  "override_attributes": {
    "objectstorage": {
      "username": "*************:*********",
      "apikey": "****************************************************************",
      "authurl": "https://tok02.objectstorage.softlayer.net/auth/v1.0/"
    }
  },
  "chef_type": "role",
  "run_list": [
    "recipe[objectStorage01]"
  ],
  "env_run_lists": {

  }
}
```


Contributing
------------
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github


License and Authors
-------------------

see LICENCE file

Authors: Maho Takara

