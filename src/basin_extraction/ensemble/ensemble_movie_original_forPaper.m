%%% ensembleのrainMatrixの72時間雨量を計算
%%% 流域に関わる計算点のみ表示
%%% 画像を出力

%% パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basin = 'chikugo'; % 流域
h = 72; % 雨量の期間(hours, 12<=h<=360 & mod(h,12)=0)
targetTime = '201707040900'; % 対象期間の開始時刻(yyyyMMddHHmm)
initTime = '201707010900'; % 図を表示させたい初期時刻(yyyyMMddHHmm)
% アンサンブル予測のcsvファイル(basinのものであれば何でも良い)
ensCSV = fullfile(projectFolder,'ensemble',basin, ...
                  sprintf('%s_01.csv',targetTime));
% RainMatrixがあるフォルダ
rainMatrixFolder = fullfile(projectFolder,'ProcessedRain','rainMatrix', ...
                            'ensemble',basin,sprintf('%dhours',h),targetTime);
% アンサンブル予測の計算点の支配領域面積のcsvファイル
areaFile = fullfile(projectFolder,'geoData',basin, ...
                      sprintf('%s_area_per_enscell.csv',basin));

%% 流域内に支配領域を持つアンサンブルの計算点のidxを取得
% basinを覆う計算点の番号を取得
areaData = readmatrix(areaFile,"NumHeaderLines",1);
area = areaData(:,2); % 支配面積
targetIdx = find(area ~= 0);

%% アンサンブル格子の緯度経度を取得
ensFile = readmatrix(ensCSV,'NumHeaderLines',0,'Delimiter',',');
ROW = ensFile(1,13); % アンサンブル予測のグリッドの行数
COL = ensFile(1,12); % アンサンブル予測のグリッドの列数
north = ensFile(1,15); % 最北端の緯度
west = ensFile(1,14); % 最西端の経度
lat = zeros(1,ROW*COL); % 緯度
lon = zeros(1,ROW*COL); % 経度
for i = 1:ROW*COL
    lat(i) = north-0.05/2-0.05*mod(i-1,ROW);
    lon(i) = west+0.0625/2+0.0625*floor((i-1)/ROW);
end
% 流域内に支配領域を持つアンサンブルの計算点の緯度経度のみを抽出
inBasinLat = lat(targetIdx);
inBasinLon = lon(targetIdx);

%% rainMatrixの読み込み
totalRain = zeros(51,ROW*COL);
for mem = 1:51
    tempTotalRain = readmatrix(fullfile(rainMatrixFolder, ...
                                        sprintf('%s_%s_%03d.dat', ...
                                        basin,initTime,mem)));
    totalRain(mem,:) = sum(tempTotalRain,2);
end
% 流域内に支配領域を持つアンサンブルの計算点の雨量のみを抽出
inBasinTotalRain = totalRain(:,targetIdx);

%% 地図に色塗り→動画作成
% 国土地理院の白地図を読み込み
basemapName = "GSImap";
url = "https://cyberjapandata.gsi.go.jp/xyz/blank/{z}/{x}/{y}.png"; 
attribution = ".";
% attribution = "国土地理院発行の白地図を加工して作成";
addCustomBasemap(basemapName,url,"Attribution",attribution)

% colorbarの設定
maxTotalRain = max(inBasinTotalRain,[],"all"); % totalRainの最大値
minTotalRain = min(inBasinTotalRain,[],"all"); % totalRainの最小値
intervalTickLabels = 100; % 目盛りの最小単位(mm)
maxTickLabels = ceil(maxTotalRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最大値
minTickLabels = floor(minTotalRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最小値

% 地図に色塗り
color = turbo; % カラーマップ(color = flip(gray))

fig = figure('Position',[100 100 800 500]); % 3列目が幅，4列目が高さ
fig.Color = 'white';
t = tiledlayout(8,7);
t.Padding = 'compact'; t.TileSpacing = 'none';

for mem = 1:51
    
    % gx = geoaxes(t,'Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes(t,'Basemap','bluegreen'); % MATLABの緑青地図
    for i = 1:length(targetIdx)
        facecolor = color(round((inBasinTotalRain(mem,i) ...
                                 -minTickLabels) ...
                                /(maxTickLabels-minTickLabels) ...
                                *(size(color,1)-1)+1), ...
                          :); % 塗りつぶしの色
        gp = geoplot(inBasinLat(i),inBasinLon(i),'square');
        gp.MarkerFaceColor = facecolor;
        gp.MarkerEdgeColor = 'none';
        hold on
    end
    hold off

    % titleの設定
    if mem==51
        startTime = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
        startTime.Format = 'yyyy/MM/dd HH:mm'; % 対象期間の開始時刻
        endTime = startTime + hours(h);
        endTime.Format = 'MM/dd HH:mm'; % 対象期間の終了時刻
        dtInitTime = datetime(initTime,'InputFormat','yyyyMMddHHmm');
        dtInitTime.Format = 'MM/dd HH:mm';
        title(gx,sprintf('Target period: %s - %s\nInitial time: %s', ...
                         startTime,endTime,dtInitTime), ...
              'Units','normalized','Position',[2 0.05], ...
              'HorizontalAlignment','left')
    end

    gx.Layout.Tile = mem;
    % gx.ZoomLevel = 8;
    gx.Grid = "off";
    gx.LatitudeAxis.Visible = 'off';
    gx.LongitudeAxis.Visible = 'off';
    gx.LatitudeAxis.TickLabels = '';
    gx.LongitudeAxis.TickLabels = '';
    gx.Scalebar.Visible = 'off';
end

% colorbarの設定
colormap(color)
cb = colorbar;
cb.Ticks = linspace(0,1,3);
cb.TickLabels = {sprintf('%d mm',minTickLabels), ...
                 sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                 sprintf('%d',maxTickLabels)};
cb.Position = [.33,.02,.02,.12]; % [left, bottom, width, height]

fontname(fig,'Arial')
fontsize(12,'points')