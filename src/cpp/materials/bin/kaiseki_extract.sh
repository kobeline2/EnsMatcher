#!/bin/bash

# 気象庁解析雨量の元データから4バイト整数の配列を取り出す（grib2_decを実行）

# 年月日
year=2018 # 年
month=08 # 月
start_date=04 # 開始日
end_date=07 # 終了日

# パス
grib2_dec_path="../SAMPLE_C/grib2_dec" # grib2_decがあるディレクトリ
rain_base_path="../DATA" # 解析雨量があるディレクトリ

# 日時ごとにgrib2_decを実行
for date in $(seq -w $start_date $end_date); do
    for current_time in $(seq -w 000000 10000 230000); do
        rain_path="$rain_base_path/$year/$month/$date/Z__C_RJTD_"$year""$month""$date""$current_time"_SRF_GPV_Ggis1km_Prr60lv_ANAL_grib2.bin"
        $grib2_dec_path $rain_path # grib2_decを実行
    done
done