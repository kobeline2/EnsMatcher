function makeGifKaiseki(outMovieFile, resampledRain, targetTime, latD4pdf, lonD4pdf)
% idD4pdfcell needed.
% 地図に色塗り → 動画作成
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
for iTime = 1:h
    tmpDate = tmpDate + hours;
    fig = figure('Position',[100 100 250 250], ...
                 'Visible','off'); % 3列目が幅，4列目が高さ
    fig.Color = 'white';

    % gx = geoaxes('Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes('Basemap','bluegreen'); % MATLABの緑青地図
    for i = 1:length(idD4pdfcell)
        facecolor = color(round((resampledRain(i,iTime) ...
                                 -minTickLabels) ...
                                /(maxTickLabels-minTickLabels) ...
                                *(size(color,1)-1)+1), ...
                          :); % 塗りつぶしの色
        gp = geoplot(latD4pdf(i),lonD4pdf(i),'o');
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
    fprintf('%d/%d %s\n',iTime,h,datetime('now','Format','HH:mm:ss'))
    close(fig)
end
close(video)
end