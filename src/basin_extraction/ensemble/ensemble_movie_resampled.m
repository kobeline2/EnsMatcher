%%% ensembleのresampling後の動画を作成 %%%

%% パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basin = 'miya'; % 流域
h = 72; % 雨量の期間(hours, 12<=h<=360 & mod(h,12)=0)
targetTime = '201710200900'; % 対象期間の開始時刻(yyyyMMddHHmm)
initTime = '201710160900'; % 図を表示させたい初期時刻(yyyyMMddHHmm)
% アンサンブル予測のcsvファイル(basinのものであれば何でも良い)
sampleEnsFile = fullfile(projectFolder,'ensemble',basin, ...
                         sprintf('%s_01.csv',targetTime));
% ensembleのRainMatrixがあるフォルダ
processedEnsFolder = fullfile(projectFolder,'ProcessedRain','rainMatrix', ...
                              'ensemble',basin,sprintf('%dhours',h),targetTime);
% d4PDF計算点の支配面積のデータファイル
d4pdfAreaFile = fullfile(projectFolder,'geoData',basin, ...
                         sprintf('%s_area_per_d4pdfcell.csv',basin));
% d4PDFの計算点の緯度経度のデータファイル
d4pdfLocationFile = fullfile(projectFolder,'d4PDF','d4PDF_5kmDDS_JP', ...
                             'cnst','location.csv');
% 出力する動画ファイル
outMovieFile = fullfile(projectFolder,'Movie',basin,'ensemble', ...
                        sprintf('%dhours',h),targetTime, ...
                        sprintf('%s_%s_resampled.mp4',basin,initTime));


%% アンサンブル予測のグリッドの緯度経度を取得(resamplingの準備)
ensFile = readmatrix(sampleEnsFile,'NumHeaderLines',0,'Delimiter',',');
nRow     = ensFile(1,13); % アンサンブル予測のグリッドの行数
nCol     = ensFile(1,12); % アンサンブル予測のグリッドの列数
west    = ensFile(1,14); % 最西端の経度
east    = ensFile(1,16); % 最東端の経度
north   = ensFile(1,15); % 最北端の緯度
south   = ensFile(1,17); % 最南端の緯度
dx      = 0.0625;        % x(経度)方向のグリッドの間隔
dy      = 0.05;          % y(緯度)方向のグリッドの間隔

% アンサンブルメッシュの中心の経度緯度
[ensLon,ensLat] = meshgrid(west +dx/2 : dx : east -dx/2, ...
                           north-dy/2 :-dy : south+dy/2);


%% d4PDFの計算点の緯度経度を取得(resamplingの準備)
% basinを覆う計算点の番号を取得
d4pdfArea = readmatrix(d4pdfAreaFile,"NumHeaderLines",1);
id = d4pdfArea(:,1); % 通し番号

% 計算点の緯度経度を取得
d4pdfLocation = readmatrix(d4pdfLocationFile,"NumHeaderLines",1);
d4pdfLon = d4pdfLocation(id,5); % 経度
d4pdfLat = d4pdfLocation(id,4); % 緯度


%% rainMatrixの読み込み → resampling
ensRain = zeros(51,nRow*nCol*h); % resampling前の雨
reEnsRain = zeros(51,length(id)*h); % resampling後の雨
for mem = 1:51 % アンサンブル予測のメンバー(通常はmem = 1:51)
    % rainMatrixの読み込み
    tempEnsRain = readmatrix(fullfile(processedEnsFolder, ...
                                      sprintf('%s_%s_%03d.dat', ...
                                              basin,initTime,mem)));
    ensRain(mem,:) = reshape(tempEnsRain,[1,nRow*nCol*h]);
    % resampling
    for t = 1:h
        tEnsRain = reshape(tempEnsRain(:,t),[nRow,nCol]);
        tCol = (t-1)*length(id); % 経過時間×d4PDFの計算点の数
        reEnsRain(mem,tCol+1:tCol+length(id)) ...
        = interp2(ensLon,ensLat,tEnsRain,d4pdfLon,d4pdfLat);
    end
end


%% 地図上にplot → 動画作成
% colorbarの設定
maxRain = max(ensRain,[],"all"); % rainMatrixの最大値
minRain = min(ensRain,[],"all"); % rainMatrixの最小値
intervalTickLabels = 10; % 目盛りの最小単位(mm)
maxTickLabels = ceil(maxRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最大値
minTickLabels = floor(minRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最小値
color = turbo; % カラーマップ(color = flip(gray))

% titleの設定
initTime = datetime(initTime,'InputFormat','yyyyMMddHHmm');
initTime.Format = 'yyyy/MM/dd HH:mm';
currentTime = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
currentTime.Format = 'yyyy/MM/dd HH:mm';

% 動画の設定
video = VideoWriter(outMovieFile,'MPEG-4');
video.FrameRate = 7;
open(video);

% 地図上にplot
for t = 1:h
    currentTime = currentTime + hours;
    fig = figure('Position',[100 100 800 500], ...
                 'Visible','off'); % 3列目が幅，4列目が高さ
    fig.Color = 'white';
    tile = tiledlayout(8,7);
    tile.Padding = 'compact'; tile.TileSpacing = 'none';
    for mem = 1:51
        gx = geoaxes(tile,'Basemap','bluegreen'); % MATLABの緑青地図
        hold on
        for i = 1:length(id)
            facecolor = color(round((reEnsRain(mem,length(id)*(t-1)+i) ...
                                     -minTickLabels) ...
                                    /(maxTickLabels-minTickLabels) ...
                                    *(size(color,1)-1)+1), ...
                              :); % 塗りつぶしの色
            gp = geoplot(d4pdfLat(i),d4pdfLon(i),'o');
            gp.MarkerFaceColor = facecolor;
            gp.MarkerEdgeColor = 'none';
        end
        hold off

        % 最後の図の横にtitleを追加
        if mem==51
            title(gx,sprintf('Current time: %s\nInitial time: %s', ...
                             currentTime,initTime), ...
                  'Units','normalized','Position',[2 0.05], ...
                  'HorizontalAlignment','left')
        end
        gx.Layout.Tile = mem;
        % gx.ZoomLevel = 8;
        gx.Grid = 'off';
        gx.LatitudeAxis.Visible = 'off';
        gx.LongitudeAxis.Visible = 'off';
        gx.LatitudeAxis.TickLabels = '';
        gx.LongitudeAxis.TickLabels = '';
        gx.Scalebar.Visible = 'off';
    end

    % colorbarを追加
    colormap(color)
    cb = colorbar;
    cb.Ticks = linspace(0,1,3);
    cb.TickLabels = {sprintf('%d mm/h',minTickLabels), ...
                     sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                     sprintf('%d',maxTickLabels)};
    cb.Position = [.33,.02,.02,.12]; % [left, bottom, width, height]

    fontname(fig,'Arial')
    fontsize(12,'points')

    % 動画に書き込み
    frame = getframe(fig);
    writeVideo(video,frame);

    close(fig)
    fprintf('%d/%d %s\n',t,h,datetime('now','Format','HH:mm:ss'))    
end
close(video)