%%% d4PDFの時間分布のクラスタリング %%%

%% 1.パラメータの設定
basin = 'agano'; % 流域
h = 72; % 対象期間(hours)
nRank = 3; % 年何位までの雨量を用いるか(1~5)
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
d4pdfFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                       'ProcessedRain','nHoursRain','d4pdf', ...
                       basin,sprintf('%dhours',h));
filename = '*.dat'; % 読み込みたい雨量データのファイル名
doNormalization = 'yes'; % 正規化するか('yes'or'no')
methodClustering = 'ward2'; % 'kmeans','ward1'or'ward2'
threshold = 0.8; % 不整合係数の閾値
nCluster = 6; % 作成するクラスターの数(threshold or nCluster のどちらか一方を設定)
nCol = 3; % ハイエトグラフの列数
% 変数を保存するMATファイル
outMatFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                      'Result',basin,sprintf('%dhours',h),'clustering','time', ...
                      sprintf('%s_clustering_time_%d_%s.mat', ...
                              basin,nCluster,doNormalization));

%% 2.d4PDF雨量データの読み込み(+正規化)
rain = zeros(0,h);
for iRank = 1:nRank  
    datFiles = dir(fullfile(d4pdfFolder,num2str(iRank),filename));
    nDatFile = length(datFiles);
    tempRain = zeros(nDatFile,h);
    for i = 1:nDatFile
        tempRain(i,:) = readmatrix(fullfile(datFiles(i).folder,datFiles(i).name));
    end
    rain = vertcat(rain,tempRain); % 行列を連結
end

% 正規化
if strcmp(doNormalization,'yes') == 1
    rain = normalize(rain,2,'norm',1);
end

%% 3.クラスタリング
switch methodClustering
    case 'kmeans' % k-means法
        rng("default") % For reproducibility
        idx = kmeans(rain,nCluster,'Start','sample');

    case 'ward1' % ウォード法(テンドログラムを描画する)
        % オブジェクト間のユークリッド距離を計算
        euclid = pdist(rain);
        % 近接するオブジェクトのペアをリンク(ウォード法)
        link = linkage(euclid,"ward");
        % デンドログラムを描画
        figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        dendrogram(link,size(rain,1))
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
        idx = clusterdata(rain,'Linkage','ward','MaxClust',nCluster);
end

%% 4.各クラスターの平均総雨量を計算して，少ない順にクラスター番号を再度割り振る
if strcmp(doNormalization,'no') == 1
    aveRain = zeros(1,nCluster); % 配列の事前割り当て
    for i = 1:nCluster
        % 各クラスタに属する降雨群のクラスター内平均を計算
        aveRain(i) = mean(sum(rain(idx==i,:),2));
    end
    % h時間総雨量の平均値が小さい順に並び替え
    [aveRain,I] = sort(aveRain,'ascend');
    % 平均値に応じてidxを置換(最小idx=1)
    for i = 1:nCluster
        idx(idx==I(i)) = i+length(idx);
    end
    idx = idx-length(idx); % 2行前で加えたlength(idx)を引く
end

%% 5.各クラスターに分類されたハイエトグラフの個数を取得
nRainPerCluster = zeros(1,nCluster); % 配列の事前割り当て
for i = 1:nCluster
    nRainPerCluster(i) = nnz(idx==i);
end

%% 6.各クラスターの重心を計算
centRain = zeros(nCluster, size(rain,2)); % 配列の事前割り当て
for i = 1:nCluster
    clusRain = rain(idx==i,:); % 同じクラスターの雨をまとめる
    centRain(i,:) = mean(clusRain, 1); % 各クラスターの重心を求める
end

%% 7-1.ハイエトグラフ描画(各クラスターの平均降雨波形)
figure('Position',[500 200 1000 300]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';
color = colororder("gem12"); % 12色まで対応
for i = 1:nCluster
    nexttile
    % idxの値で色を分けてハイエトグラフを描画
    bar(centRain(i,:),'FaceColor',color(mod(i,size(color,1))+1,:))
    xlim([0 h])
    xticks(0:24:h)
    switch doNormalization
        case 'yes'
            ylim([0 0.15])
            yticks(0:0.05:0.15)
            ytickformat('%.2f')
        case 'no'
            ylim([0 30])
            yticks(0:10:30)
    end
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
xlabel(t,'time [hour]','Fontsize',18)
switch doNormalization
    case 'yes'
        ylabel(t,'rain','Fontsize',18)
    case 'no'
        ylabel(t,'rain [mm/h]','Fontsize',18)
end

%% 7-2.ハイエトグラフ描画(全部重ね合わせる)
figure('Position',[500 200 1000 500]) % 3列目が幅，4列目が高さ
t = tiledlayout(ceil(nCluster/nCol),nCol);
t.Padding = 'compact'; t.TileSpacing = 'compact';
for i = 1:nCluster
    nexttile
    plot(rain(idx==i, :)', '-', 'Color',[0 0 0 0.1])
    title(['Cluster ' num2str(i)])
    xlim([0 h])
    xticks(0:24:h)
    switch doNormalization
        case 'yes'
            ylim([0 0.45])
            yticks(0:0.15:0.45)
            ytickformat('%.2f')
        case 'no'
            ylim([0 30])
            yticks(0:10:30)
    end
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
xlabel(t,'time [hour]','Fontsize',18)
switch doNormalization
    case 'yes'
        ylabel(t,'rain','Fontsize',18)
    case 'no'
        ylabel(t,'rain [mm/h]','Fontsize',18)
end

%% 8.ワークスペースの変数を保存
switch doNormalization
    case 'yes'
        save(outMatFile,"basin","h","doNormalization", ...
            "nCluster","idx","nRainPerCluster","centRain")
    case 'no'
        save(outMatFile,"basin","h","doNormalization", ...
            "nCluster","idx","aveRain","nRainPerCluster","centRain")
end