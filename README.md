objectStorage01 Cookbook
========================
SoftLayerのオブジェクト・ストレージをブロック・ストレージとしてマウント出来る様に、
CloudFuse の導入、fstabの設定をおこない、/os をマウントします。 

この設定は、起動時にも自動マウントしますから、継続的に利用していけます。

このCookbookに、Cloudfuse が含まれていますが、最新版と入れ替えるには、
https://github.com/redbo/cloudfuse から取得して入れ替えをお願いします。

このGitHUBの内容に関する少し詳しい説明は、**qiita** の投稿してありますので、併せて参照いただけると詳しく把握いただけます。 http://qiita.com/MahoTakara/items/8e013b3ef1ad9c663c18


要件(Requirements)
------------

- Chef 12.5 以上 (これより前のバージョンで確認していません。)
- Ubuntu 14.04 LTS 64bit
- CentOS 6.x 64bit
- CentOS 7.x 64bit


属性(Attributes)
----------
オブジェクト・ストレージをアクセスするために必要な認証情報は、https://control.softlayer.com/ -> 'Storage' -> 'Object Storage' -> Datacenter -> 'View Credentials' に表示される値を利用します。


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
本クックブックの適用方法として、スタンドアロン、knife リモート適用、Chef Server 利用の３パターンをご紹介します。


#### スタンドアロンで実行する方法

knife や chef-server を使わず、chef-solo コマンドを利用するだけの方法です。
プロビジョニング完了後に、設定対象サーバーにログインして、以下のコマンドを順次実行してきます。
ここでknifeを実行する理由は、/var/chef/cookbooks のディレクトを作成するためです。

```
# curl -L https://www.opscode.com/chef/install.sh | bash
# knife cookbook create dummy -o /var/chef/cookbooks
# cd /var/chef/cookbooks
# git clone https://github.com/takara9/objectStorage01
```
git のバージョンが1.9以降であれば、次の様に一回で落とせます。

```
# git -C /var/chef/cookbooks clone https://github.com/takara9/objectStorage01
```
適応前に、オブジェクト・ストレージの認証情報をattributesのファイルに設定します。

```
# vi objectStorage01/attributes/default.rb 
```
準備が完了したら objectStorage01 クックブックを適用します。

```
# chef-solo -o objectStorage01
< 中略 >
Running handlers complete
Chef Client finished, 13/14 resources updated in 01 minutes 15 seconds
```




#### Knife Solo で利用する方法 
レポジトリ用のディレクトリを作成して初期化します。

```
$ mkdir chef-solo-repo
$ cd chef-solo-repo
$ knife solo init .
```
site-cookbooksの下にクックブックをクローンします。

```
$ cd site-cookbooks/
$ git clone https://github.com/takara9/objectStorage01 
```
一応、GitHubから落ちてきているか確認しておきます。

```
$ pwd
/home/chef/chef-solo-repo/site-cookbooks
$ ls
objectStorage01
```
attributes/default.rb を編集して認証情報をセットした後、
hostnameのインスタンスに、クックブックを適用します。

```
$ cd /home/chef/chef-solo-repo
$ knife solo bootstrap root@hostname -i sshkey -r 'recipe[objectStorage01]'
```

#### Knife Server/WorkStation から利用する方法
Chef WorkStaion のリポジトリに移動して、クックブックをクローンします。

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

クックブックの適用結果を確認します。次の様に'/os'がマウントされていれば成功です。

```
# df
ファイルシス   1K-ブロック    使用     使用可 使用% マウント位置
/dev/xvda2        25412940 1763356   22352024    8% /
devtmpfs            497688       0     497688    0% /dev
tmpfs               505924       0     505924    0% /dev/shm
tmpfs               505924    6620     499304    2% /run
tmpfs               505924       0     505924    0% /sys/fs/cgroup
/dev/xvda1          245679  133940      98632   58% /boot
cloudfuse       8589934588       0 8589934588    0% /os
```
lsコマンドを実行するとオブジェクト・ストレージのコンテナのリストが表示されます。
/os直下は、コンテナに対応していないので、ファイルを保存できない点が注意です。

```
# ls -al /os
合計 4
drwxrwx---   2 root  106    0  1月  1  1970 .
drwxr-xr-x. 19 root root 4096 11月  9 10:01 ..
drwxrwx---   2 root  106    0 11月  9 10:02 archive
drwxrwx---   2 root  106    0 11月  9 10:02 backup_contents
drwxrwx---   2 root  106    0 11月  9 10:02 backup_dbdata
drwxrwx---   2 root  106    0 11月  9 10:02 log
```

# 参考情報
#### role から上書き設定する場合

roleのオーバーライドに設定する場合の例を以下に示します。

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
      "authurl": "****************************************************"
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

see LICENSE

Authors: Maho Takara

