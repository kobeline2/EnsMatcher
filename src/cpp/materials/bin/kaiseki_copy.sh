#!/bin/bash

# 防災研のサーバーから気象庁解析雨量をコピーする

# 年月日
year=2017 # 年
month=10 # 月
start_date=24 # 開始日
end_date=25 # 終了日

# YEARが2019以下ならtempYEARに"2006-2019"を代入
if [ $year -eq 2020 ]; then
  tempYear="2020"
elif [ $year -le 2019 ]; then
  tempYear="2006-2019"
fi

# パス
remote_host="guest@10.244.84.226" # サーバーのホスト名
remote_base_path="/gluster2/data/Radar_AMeDAS/$tempYear/DATA" # サーバー上のベースディレクトリ
local_base_path="../DATA" # ローカルのコピー先ディレクトリ

# 日付ごとにループしてコピー
for date in $(seq $start_date $end_date); do
  remote_path="$remote_base_path/$year/$month/$date/"
  local_path="$local_base_path/$year/$month/"
  mkdir -p "$local_path" # ローカルのディレクトリが存在しない場合、作成
  scp -r -oHostKeyAlgorithms=+ssh-rsa -oKexAlgorithms=+diffie-hellman-group1-sha1 "$remote_host:$remote_path" "$local_path"
done