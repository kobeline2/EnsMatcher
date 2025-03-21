%%% 気象庁解析雨量から指定した流域の雨を抽出する → resampling → 動画作成 %%%

%% パラメータの設定
basin = 'miya'; % 流域
h = 72; % 雨の期間
targetTime = '201710200900'; % 対象期間の開始時刻(日本時間)'yyyyMMddHHmm'
% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','geoData',basin);
% d4PDFの計算点の緯度経度の情報が入ったcsvファイル
locationFile = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\cnst\location.csv';
% 気象庁解析雨量のデータがあるフォルダ
kaisekiFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                         'kaiseki','DATA');
% resample後の流域の雨を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                     'ProcessedRain','nHoursRain','kaiseki', ...
                     basin,sprintf('%dhours',h), ...
                     sprintf('%s_%s.dat',basin,targetTime));
% 出力する動画ファイル
% outMovieFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
%                         'Movie',basin,'kaiseki',sprintf('%dhours',h), ...
%                         sprintf('%s_%s_resampled.mp4',basin,targetTime));


%% 解析雨量の格子点の緯度経度を取得(resamplingの準備)
row = 3360; % 行数
col = 2560; % 列数
west = 118; % 領域の最西端の経度
east = 150; % 領域の最東端の経度
north = 48; % 領域の最北端の緯度
south = 20; % 領域の最南端の緯度
dx = 0.0125; % x(経度)方向の格子点の間隔
dy = 1/120; % y(緯度)方向の格子点の間隔

% 解析雨量の格子点の緯度経度
[lon,lat] = meshgrid(west +dx/2 : dx : east -dx/2, ...
                     north-dy/2 :-dy : south+dy/2);


%% d4PDFの計算点の緯度経度を取得(resamplingの準備)
% basinを覆う計算点の番号を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号

% 計算点の緯度経度を取得
locationCSV = readmatrix(locationFile,"NumHeaderLines",1);
d4pdfLon = locationCSV(id,5); % 経度
d4pdfLat = locationCSV(id,4); % 緯度


%% 解析雨量の読み込み → レベル値から雨量(mm/h)に変換 → resampling

% 協定世界時(UTC)に設定
tmpDate = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
tmpDate = tmpDate - hours(9); % UTC

resampledRain = zeros(length(id),h); % resample後の解析雨量

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
    
    % resampling
    % 解析雨量は左上から右下へ"横方向"に並んでいるため，
    % [col,row]でreshapeしてから転置する
    reshapedRain = reshape(rain,[col,row])';
    % resampling
    resampledRain(:,time) = interp2(lon,lat,reshapedRain,d4pdfLon,d4pdfLat);
end


%% resampledRainをdatファイルに出力
writematrix(resampledRain,outFile)


%% 地図に色塗り → 動画作成
% 国土地理院の白地図を読み込み
basemapName = "GSImap";
url = "https://cyberjapandata.gsi.go.jp/xyz/blank/{z}/{x}/{y}.png"; 
attribution = ".";
% attribution = "国土地理院発行の白地図を加工して作成";
addCustomBasemap(basemapName,url,"Attribution",attribution)

% colorbarの設定
maxRain = max(resampledRain,[],"all"); % resampledRainの最大値
minRain = min(resampledRain,[],"all"); % resampledRainの最小値
intervalTickLabels = 10; % 目盛りの最小単位(mm)
maxTickLabels = ceil(maxRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最大値
minTickLabels = floor(minRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最小値

% titleの設定
tmpDate = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
tmpDate.Format = 'yyyy/MM/dd HH:mm';

% 動画の設定
video = VideoWriter(outMovieFile,'MPEG-4');
video.FrameRate = 5;
open(video);

% 地図に色塗り
color = turbo; % カラーマップ(color = flip(gray))
for time = 1:h
    tmpDate = tmpDate + hours;
    fig = figure('Position',[100 100 250 250], ...
                 'Visible','off'); % 3列目が幅，4列目が高さ
    fig.Color = 'white';

    % gx = geoaxes('Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes('Basemap','bluegreen'); % MATLABの緑青地図
    for i = 1:length(id)
        facecolor = color(round((resampledRain(i,time) ...
                                 -minTickLabels) ...
                                /(maxTickLabels-minTickLabels) ...
                                *(size(color,1)-1)+1), ...
                          :); % 塗りつぶしの色
        gp = geoplot(d4pdfLat(i),d4pdfLon(i),'o');
        gp.MarkerFaceColor = facecolor;
        gp.MarkerEdgeColor = 'none';
        hold on
    end
    hold off
    % 凡例をつける
    colormap(color)
    cb = colorbar;
    cb.Ticks = linspace(0,1,3);
    cb.TickLabels = {sprintf('%d mm/h',minTickLabels), ...
                     sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                     sprintf('%d',maxTickLabels)};
    title(gx,sprintf('%s',tmpDate), ...
          'Units','normalized','Position',[0.5 -0.1])
    % gx.ZoomLevel = 8;
    gx.Grid = "off";
    gx.LatitudeAxis.Visible = 'off';
    gx.LongitudeAxis.Visible = 'off';
    gx.LatitudeAxis.TickLabels = '';
    gx.LongitudeAxis.TickLabels = '';
    gx.Scalebar.Visible = 'off';
    gx.FontSize = 10;
   
    frame = getframe(fig);
    writeVideo(video,frame);   
    fprintf('%d/%d %s\n',time,h,datetime('now','Format','HH:mm:ss'))
    close(fig)
end
close(video)