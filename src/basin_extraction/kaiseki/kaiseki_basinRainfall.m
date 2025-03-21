%%% 気象庁解析雨量を用いて流域平均総雨量を計算する（対象期間決定のため） %%%

%% パラメータの設定
basin = 'mogami'; % 流域
h = 72; % 雨の期間
targetTime = '202208020900'; % 対象期間の開始時刻(日本時間)'yyyyMMddHHmm'
% 解析雨量メッシュの支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% 解析雨量のデータがあるフォルダ
kaisekiFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                         'kaiseki','DATA');


%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_kaisekicell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号
area = areaCSV(:,2); % ティーセン分割によって作られた各領域が流域と重なる面積


%% 解析雨量の読み込み → レベル値から雨量(mm/h)に変換 → 流域平均総雨量を計算

% 協定世界時(UTC)に設定
tmpDate = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
tmpDate = tmpDate - hours(9); % UTC

basinMeanTotalRain = 0; % 流域平均総雨量

for time = 1:h
    % 時刻の更新(+1h)
    tmpDate = tmpDate + hours;
    Y = tmpDate.Year;
    M = tmpDate.Month;
    D = tmpDate.Day;
    H = tmpDate.Hour;

    % 解析雨量の読み込み
    filename = sprintf('Z__C_RJTD_%d%02d%02d%02d0000_SRF_GPV_Ggis1km_Prr60lv_ANAL_0_int.bin', ...
                       Y,M,D,H);
    fid = fopen(fullfile(kaisekiFolder, ...
                         sprintf('%d',Y),sprintf('%02d',M),sprintf('%02d',D), ...
                         filename));
    tempRain = fread(fid,'int');
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

    % 流域の雨を抽出
    basinRain = rain(id);    
    % 加重平均(1時間ごとの流域平均雨量)を計算
    basinMeanRain = basinRain'*area/sum(area);  
    % 流域平均総雨量を計算
    basinMeanTotalRain = basinMeanTotalRain + basinMeanRain;
end