function saveMovieClustered(outMovieFile)
nCol = 3; % 図の列数
% 9.地図に色塗り→動画作成
% 国土地理院の白地図を読み込み
basemapName = "GSImap";
url = "https://cyberjapandata.gsi.go.jp/xyz/blank/{z}/{x}/{y}.png"; 
attribution = ".";
% attribution = "国土地理院発行の白地図を加工して作成";
addCustomBasemap(basemapName,url,"Attribution",attribution)

% colorbarの設定
maxMeanRain = max(centRain,[],"all"); % meanRainの最大値
minMeanRain = min(centRain,[],"all"); % meanRainの最小値
intervalTickLabels = 10; % 目盛りの最小単位(mm)
maxTickLabels = ceil(maxMeanRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最大値
minTickLabels = floor(minMeanRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最小値

% 動画の設定
video = VideoWriter(outMovieFile, 'MPEG-4');
video.FrameRate = 6;
video.Quality = 100;
open(video);

% 地図に色塗り
color = turbo; % カラーマップ(color = flip(gray))
for time = 1:h
    % fig = figure('Position',[500 200 1000 250*ceil(cfg.nCluster/nCol)], ...
    %              'Visible','off'); % 3列目が幅，4列目が高さ
    fig = figure('Units','centimeters', ...
                 'Position',[10 5 20 6*ceil(cfg.nCluster/nCol)], ...
                 'Visible','off'); % 3列目が幅，4列目が高さ
    fig.Color = 'white';
    t = tiledlayout(ceil(cfg.nCluster/nCol),nCol);
    t.Padding = 'compact'; t.TileSpacing = 'compact';
    for iCluster = 1:cfg.nCluster
    % gx = geoaxes(t,'Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes(t,'Basemap','bluegreen'); % MATLABの緑青地図
        for i = 1:nCell
            facecolor = color(round((centRain(iCluster, nCell*(time-1)+i) ...
                                     -minTickLabels) ...
                                    /(maxTickLabels-minTickLabels) ...
                                    *(size(color,1)-1)+1), ...
                              :); % 塗りつぶしの色
            gp = geoplot(lat(i),lon(i),'o');
            gp.MarkerFaceColor = facecolor;
            gp.MarkerEdgeColor = 'none';
            hold on          
        end
        hold off
        % 最後の図の横に凡例をつける
        if iCluster==cfg.nCluster
            colormap(color)
            cb = colorbar;
            cb.Ticks = linspace(0,1,3);
            cb.TickLabels = {sprintf('%d mm/h',minTickLabels), ...
                             sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                             sprintf('%d',maxTickLabels)};
        end
        title(sprintf('Cluster %d   n = %d',iCluster,nPerCluster(iCluster)))
        gx.Layout.Tile = iCluster;
        % gx.ZoomLevel = 8;
        gx.Grid = 'off';
        gx.LatitudeAxis.Visible = 'off';
        gx.LongitudeAxis.Visible = 'off';
        gx.LatitudeAxis.TickLabels = '';
        gx.LongitudeAxis.TickLabels = '';
        gx.Scalebar.Visible = 'off';
        % gx.FontSize = 12;
    end
    % annotation('textbox',[.01 .67 .1 .2],'String',sprintf('t=%02dh',time), ...
    %            'EdgeColor','none','FontSize',14)
    annotation('textbox',[.88 .71 .1 .2],'String',sprintf('t=%02dh',time), ...
               'EdgeColor','none')
    fontname(fig,'Arial')
    fontsize(14,'points')
    frame = getframe(fig);
    writeVideo(video,frame);
    fprintf('%d/%d %s\n',time,h,datetime('now','Format','HH:mm:ss'))
    close(fig)
end
close(video)
end