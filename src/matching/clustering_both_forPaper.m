%%% d4PDFの時空間分布のクラスタリング %%%
%%% 論文掲載用にfigureのサイズ等を調整

%% 1.パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basin = 'chikugo'; % 流域
h = 72; % 対象期間(hours)
nRank = 3; % 年何位までの雨量を用いるか(1~5)
clusteringMethod = 'ward'; % 'kmeans','ward'or'cos'
nCluster = 6; % 作成するクラスターの数
nCol = 6; % 図の列数

% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile(projectFolder,'geoData',basin);
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
d4pdfFolder = fullfile(projectFolder,'ProcessedRain','rainMatrix','d4pdf', ...
                       basin,sprintf('%dhours',h));
filename = '*.dat'; % 読み込みたい雨量データのファイル名
% d4PDFの計算点の緯度経度の情報が入ったCSVファイル
locationFile = fullfile(projectFolder,'d4PDF','d4PDF_5kmDDS_JP','cnst', ...
                        'location.csv');
% 出力する動画ファイル
outMovieFile = fullfile(projectFolder,'Result',basin, ...
                        sprintf('%dhours',h),'clustering','both', ...
                        sprintf('%s_clustering_both_forPaper_%d_%s.mp4', ...
                                basin,nCluster,clusteringMethod));
% 変数を保存するMATファイル
outMatFile = fullfile(projectFolder,'Result',basin, ...
                      sprintf('%dhours',h),'clustering','both', ...
                      sprintf('%s_clustering_both_forPaper_%d_%s.mat', ...
                              basin,nCluster,clusteringMethod));

%% 2.ティーセン分割後の各領域のid(番号)を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号

%% 3.d4PDF雨量データの読み込み
rain = zeros(0,length(id)*h);
for iRank = 1:nRank  
    datFiles = dir(fullfile(d4pdfFolder,num2str(iRank),filename));
    nDatFile = length(datFiles);
    tempRain = zeros(nDatFile,length(id)*h);
    for i = 1:nDatFile
        tempRain(i,:) = reshape(readmatrix(fullfile(datFiles(i).folder, ...
                                                    datFiles(i).name)), ...
                                [1,length(id)*h]);
    end
    rain = vertcat(rain,tempRain); % 行列を連結
end

%% 4.クラスタリング
switch clusteringMethod
    case 'kmeans' % k-means法
        rng("default") % For reproducibility
        idx = kmeans(rain,nCluster,'Start','sample');

    case 'ward' % ウォード法(テンドログラムを描画する)
        % オブジェクト間のユークリッド距離を計算
        euclid = pdist(rain);
        % 近接するオブジェクトのペアをリンク(ウォード法)
        link = linkage(euclid,"ward");
        % デンドログラムを描画
        figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        dendrogram(link,size(rain,1))
        % 作成するクラスターの数を指定
        idx = cluster(link,"maxclust",nCluster);

    case 'cos' % コサイン類似度
        cos = pdist(rain,'cosine');
        link = linkage(cos,'complete'); % 完全連結法
        figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        dendrogram(link,size(rain,1))
        idx = cluster(link,'maxclust',nCluster);
        % idx = clusterdata(rain,'Distance','cosine','Linkage','average','Maxclust',nCluster);
end


%% 5.各クラスターの重心を計算
centRain = zeros(nCluster,size(rain,2));
for iCluster = 1:nCluster
    centRain(iCluster,:) = mean(rain(idx==iCluster,:),1);
end

%% 6.各クラスターの流域総雨量を計算して，少ない順にクラスター番号を再度割り振る
% h時間流域総雨量のクラスター平均値が小さい順に並び替え
[~,I] = sort(sum(centRain,2),'ascend');
% 平均値に応じてidxを置換(最小idx=1)
for i = 1:nCluster
    idx(idx==I(i)) = i+length(idx);
end
idx = idx-length(idx); % 2行前で加えたlength(idx)を引く
% 新しいidxでもう一度各クラスターの重心を計算
for iCluster = 1:nCluster
    centRain(iCluster,:) = mean(rain(idx==iCluster,:),1);
end

%% 7.各クラスターに分類されたrainの個数を取得
nPerCluster = zeros(1,nCluster); % 配列の事前割り当て
for iCluster = 1:nCluster
    nPerCluster(iCluster) = nnz(idx==iCluster);
end

%% 8.d4PDFの計算点の緯度経度を取得
locationCSV = readmatrix(locationFile,"NumHeaderLines",1);
lat = locationCSV(id,4); % 緯度
lon = locationCSV(id,5); % 経度

%% 9.地図に色塗り→動画作成
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
video = VideoWriter(outMovieFile,'MPEG-4');
video.FrameRate = 5;
video.Quality = 100;
open(video);

% 地図に色塗り
color = turbo; % カラーマップ(color = flip(gray))
for time = 1:h
    fig = figure('Position',[500 200 1500 250*ceil(nCluster/nCol)], ...
                 'Visible','off'); % 3列目が幅，4列目が高さ
    % fig = figure('Units','centimeters', ...
    %              'Position',[10 5 40 6*ceil(nCluster/nCol)], ...
    %              'Visible','off'); % 3列目が幅，4列目が高さ
    fig.Color = 'white';
    t = tiledlayout(ceil(nCluster/nCol),nCol);
    t.Padding = 'compact'; t.TileSpacing = 'compact';
    for iCluster = 1:nCluster
    % gx = geoaxes(t,'Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes(t,'Basemap','bluegreen'); % MATLABの緑青地図
        for i = 1:length(id)
            facecolor = color(round((centRain(iCluster,length(id)*(time-1)+i) ...
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
        if iCluster==nCluster
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
    fontsize(14,'points')
    % annotation('textbox',[.88 .71 .1 .2],'String',sprintf('t=%02dh',time), ...
    %            'EdgeColor','none')
    annotation('textbox',[0 .4 .1 .2],'String',sprintf('t=%02dh',time), ...
               'EdgeColor','none','FontSize',18)
    fontname(fig,'Arial')
    frame = getframe(fig);
    writeVideo(video,frame);
    fprintf('%d/%d %s\n',time,h,datetime('now','Format','HH:mm:ss'))
    close(fig)
end
close(video)

%% 10.ワークスペースの変数を保存
save(outMatFile,"centRain")