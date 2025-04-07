function rain = readKaiseki(fn)
% 解析雨量を読む
fid = fopen(fn);
tempRain = fread(fid, 'int');
fclose(fid);

% レベル値から雨量(mm/h)に変換
rain = tempRain;
rain(tempRain == 0) = NaN;
rain(tempRain == 1) = 0;
rain(tempRain == 2) = 0.4;
for level = 3:79
    rain(tempRain == level) = level-2;
end
for level = 80:90
    rain(tempRain == level) = 80+(level-80)*5;
end
for level = 91:97
    rain(tempRain == level) = 140+(level-91)*10;
end
rain(tempRain == 98) = 255;

% == TO BE REPLACED TO 
% rain = fread(fid,'int');
% fclose(fid);
% 
% % レベル値から雨量(mm/h)に変換
% rain(rain == 0) = NaN;
% rain(rain == 1) = 0;
% rain(rain == 2) = 0.4;
% isTarget = (rain>=3 | rain<=79);
% rain(isTarget) = rain(isTarget)-2;
% isTarget = (rain>=80 | rain<=90);
% rain(isTarget) = 80 + (rain(isTarget)-80)*5;
% isTarget = (rain>=91 | rain<=97);
% rain(isTarget) = 140+(rain(isTarget)-91)*10;
% rain(rain == 98) = 255;


end