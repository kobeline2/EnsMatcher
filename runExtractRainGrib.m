startDateStr = '20170930';
endDateStr   = '20171004';
grib2_dec_path = fullfile('src', 'cpp', 'code', 'grib2_dec');  % grib2_dec の実行ファイルパス
rain_base_path  = fullfile('test', 'data', 'kaiseki', 'DATA'); % 雨量データのベースディレクトリ
processGribRain(startDateStr, endDateStr, grib2_dec_path, rain_base_path);

% c.f.
% terminal command to delete files end with '*int.bin'
% find . -type f -name '*int.bin' -delete