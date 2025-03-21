%%% d4PDFの空間分布のクラスタリング %%%

%% 1.パラメータの設定
basin = 'agano'; % 流域名
h = 72; % 対象期間(hours)
% クラスタリングしたい寄与率のデータを保存しているmatファイルのパス
inMatFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                     'ProcessedRain','contributionRatio','d4pdf', ...
                     basin,sprintf('%dhours',h), ...
                     sprintf('%s_contributionRatio.mat',basin));
methodClustering = 'ward1'; % 'kmeans','ward1'or'ward2'
threshold = 0.8; % 不整合係数の閾値
nCluster = 5; % 作成するクラスターの数(threshold or nCluster のどちらか一方を設定)
nCol = 5; % 図の列数
subbasinMapFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% 変数を保存するMATファイル
outMatFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                      'Result',basin,sprintf('%dhours',h),'clustering','spatial', ...
                      sprintf('%s_clustering_spatial_%d.mat',basin,nCluster));

%% 2.寄与率とsubbasinの総雨量の読み込み
load(inMatFile)

%% 3.クラスタリング
switch methodClustering
    case 'kmeans' % k-means法
        rng("default") % For reproducibility
        idx = kmeans(x,nCluster,'Start','sample');

    case 'ward1' % ウォード法
        % オブジェクト間のユークリッド距離を計算
        euclid = pdist(x);
        % 近接するオブジェクトのペアをリンク(ウォード法)
        link = linkage(euclid,"ward");
        % デンドログラムを描画(テンドログラムを描画する)
        figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        dendrogram(link,size(x,1))
        cop = cophenet(link,euclid); % コーフェン相関係数を計算(1に近いほど◎)
        inco = inconsistent(link); % 不整合係数を計算
        % 不整合係数の閾値を指定してクラスターを作成
        % idx = cluster(link,"cutoff",threshold);
        % 作成するクラスターの数を指定
        idx = cluster(link,"maxclust",nCluster);

    case 'ward2' % ウォード法(テンドログラムを描画しない)
        % 不整合係数の閾値を指定してクラスターを作成
        % idx = clusterdata(rain,'Linkage','ward','Cutoff',threshold);
        % 作成するクラスターの数を指定
        idx = clusterdata(x,'Linkage','ward','MaxClust',nCluster);
end

%% 4.各クラスターに分類されたハイエトグラフの個数を取得
nPerCluster = zeros(1,nCluster); % 配列の事前割り当て
for i = 1:nCluster
    nPerCluster(i) = nnz(idx==i);
end

%% 5.各クラスターの重心を計算
meanRatio = zeros(nCluster, size(x,2)); % 配列の事前割り当て
for i = 1:nCluster
    clusRatio = x(idx==i,:); % 同じクラスターの雨をまとめる
    meanRatio(i,:) = mean(clusRatio, 1); % 各クラスターの重心を求める
end

%% 6.各クラスターのsubbasinの流域平均雨量を抽出
meanRain = zeros(nCluster, nSubbasin);
for i = 1:nCluster
    clusRain = subbasinTotalRain(idx==i,:); % 同じクラスターの雨をまとめる
    meanRain(i,:) = mean(clusRain, 1); % 各クラスターの重心を求める
end

%% 7-1.グラフ描画(各クラスターの平均)
figure('Position',[500 200 1000 300]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';
color = colororder("gem12"); % 12色まで対応
for i = 1:nCluster
    nexttile
    % idxの値で色を分けてハイエトグラフを描画
    bar(meanRatio(i,:),'FaceColor',color(mod(i,size(color,1))+1,:))
    ylim([0 1])
    if i <= max(idx)-nCol % 最下段以外
        ax = gca;
        ax.XTickLabel = cell(size(ax.XTickLabel)); % x軸の数値を削除
    end
    if mod(i,nCol) ~= 1 % 1列目以外
        ax = gca;
        ax.YTickLabel = cell(size(ax.YTickLabel)); % y軸の数値を削除
    end
end
fontsize(14,"points")
xlabel(t,'Subbasin Number','Fontsize',18)
ylabel(t,'Contribution Ratio','Fontsize',18)

%% 7-2.グラフ描画(全部プロット)
figure('Position',[500 200 1000 300]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';
for i = 1:nCluster
    nexttile
    plot(x(idx==i, :)', '-', 'Color',[0 0 0 0.1])
    title(['Cluster ' num2str(i)])
    xlim([0.9 nSubbasin+0.1])
    xticks(1:1:nSubbasin)
    ylim([0 1])
    if i <= max(idx)-nCol % 最下段以外
        ax = gca;
        ax.XTickLabel = cell(size(ax.XTickLabel)); % x軸の数値を削除
    end
    if mod(i,nCol) ~= 1 % 1列目以外
        ax = gca;
        ax.YTickLabel = cell(size(ax.YTickLabel)); % y軸の数値を削除
    end
end
fontsize(12,"points")
xlabel(t,'Subbasin Number','Fontsize',18)
ylabel(t,'Contribution Ratio','Fontsize',18)

%% 7-3.7-1と7-2のグラフを重ね合わせる
figure('Position',[500 200 1000 300]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';
color = colororder("gem12"); % 12色まで対応
for i = 1:nCluster
    nexttile
    % idxの値で色を分けてハイエトグラフを描画
    bar(meanRatio(i,:),'FaceColor',color(mod(i,size(color,1))+1,:))
    hold on
    plot(x(idx==i, :)', '-', 'Color',[0 0 0 0.1])
    ylim([0 1])
    if i <= max(idx)-nCol % 最下段以外
        ax = gca;
        ax.XTickLabel = cell(size(ax.XTickLabel)); % x軸の数値を削除
    end
    if mod(i,nCol) ~= 1 % 1列目以外
        ax = gca;
        ax.YTickLabel = cell(size(ax.YTickLabel)); % y軸の数値を削除
    end
end
hold off
fontsize(14,"points")
xlabel(t,'Subbasin Number','Fontsize',18)
ylabel(t,'Contribution Ratio','Fontsize',18)

%% 8.subbasinの雨量に応じて地図に色塗り
% 国土地理院の白地図を読み込み
basemapName = "GSImap";
url = "https://cyberjapandata.gsi.go.jp/xyz/blank/{z}/{x}/{y}.png"; 
attribution = ".";
% attribution = "国土地理院発行の白地図を加工して作成";
addCustomBasemap(basemapName,url,"Attribution",attribution)

% figureの設定
color = flip(gray); % カラーマップ
figure('Position',[500 200 1000 150]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';

% colorbarの設定
maxMeanRain = max(meanRain,[],"all"); % meanRainの最大値
minMeanRain = min(meanRain,[],"all"); % meanRainの最小値
intervalTickLabels = 50; % 目盛りの最小単位(mm)
maxTickLabels = ceil(maxMeanRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最大値
minTickLabels = floor(minMeanRain/intervalTickLabels) ...
                *intervalTickLabels; % 目盛りの最小値

% 地図に色塗り
for i = 1:nCluster
    % gx = geoaxes(t,'Basemap','GSImap'); % 国土地理院発行の白地図
    gx = geoaxes(t,'Basemap','bluegreen'); % MATLABの緑青地図
    for j = 1:nSubbasin
        faceColor = color(round((meanRain(i,j)-minTickLabels) ...
                                /(maxTickLabels-minTickLabels) ...
                                *(size(color,1)-1)+1), ...
                          :); % 塗りつぶしの色
        subbasinMap = readgeotable(fullfile(subbasinMapFolder, ...
                                            sprintf('%s%d_basin.geojson', ...
                                                    basin,j)));
        geoplot(subbasinMap,'FaceColor',faceColor,'FaceAlpha',1);
        hold on
        % 最後の図の横に凡例をつける
        if i==nCluster && j==nSubbasin
            colormap(color)
            cb = colorbar;
            cb.Ticks = linspace(0,1,3);
            cb.TickLabels = {sprintf('%d mm',minTickLabels), ...
                             sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                             sprintf('%d',maxTickLabels)};
        end
    end
    hold off
    gx.Layout.Tile = i;
    % gx.ZoomLevel = 8;
    gx.Grid = "off";
    gx.LatitudeAxis.Visible = 'off';
    gx.LongitudeAxis.Visible = 'off';
    gx.LatitudeAxis.TickLabels = '';
    gx.LongitudeAxis.TickLabels = '';
    gx.Scalebar.Visible = 'off';
    gx.FontSize = 12;
end

%% 9.ワークスペースの変数を保存
save(outMatFile,"basin","h","nCluster","idx","nPerCluster","meanRatio")