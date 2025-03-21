%%% d4PDFの時空間分布のクラスタリング %%%
%%% 総雨量・最大降雨強度・ピーク時点を計算 %%%

%% 1.パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basin = 'chikugo'; % 流域
h = 72; % 対象期間(hours)
nRank = 3; % 年何位までの雨量を用いるか(1~5)
clusteringMethod = 'ward'; % 'kmeans','ward'or'cos'
nCluster = 6; % 作成するクラスターの数

% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile(projectFolder,'geoData',basin);
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
d4pdfFolder = fullfile(projectFolder,'ProcessedRain','rainMatrix','d4pdf', ...
                       basin,sprintf('%dhours',h));
filename = '*.dat'; % 読み込みたい雨量データのファイル名
% d4PDFの計算点の緯度経度の情報が入ったCSVファイル
locationFile = fullfile(projectFolder,'d4PDF','d4PDF_5kmDDS_JP','cnst', ...
                        'location.csv');

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

%% 諸元を計算
% 流域平均総雨量(mm)
totalBasinMeanRain = sum(centRain,2)/length(id);
% 最大降雨強度(mm/h)
maxRainIntensity = max(centRain,[],2);
% ピーク時点
basinMeanRain = zeros(nCluster,h); % 1時間ごとの流域平均雨量
for t = 1:h
    basinMeanRain(:,t) = sum(centRain(:,length(id)*(t-1)+1:length(id)*(t-1)+length(id)),2)/length(id);
end
[~,peakTime] = max(basinMeanRain,[],2); % ピーク時点
% 諸元を表示
disp(nPerCluster')
disp([totalBasinMeanRain,maxRainIntensity,peakTime])