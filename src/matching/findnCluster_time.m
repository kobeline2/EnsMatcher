%%% d4PDFをクラスタリングするうえでの適切なクラスター数を検討する(時間分布) %%%

%% 1.パラメータの設定
basin = 'miya'; % 流域
h = 72; % 対象期間(hours)
nRank = 3; % 年何位までの雨量を用いるか(1~5)
% クラスタリングしたい雨量データがあるフォルダ
d4pdfFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                       'ProcessedRain','nHoursRain','d4pdf', ...
                       basin,sprintf('%dhours',h));
filename = '*.dat'; % 読み込みたい雨量データのファイル名
doNormalization = 0; % 正規化するか(1=>yes,0=>no)
methodEvaluation = 'elbow'; % 'elbow'or'silhouette'
methodClustering = 'ward'; % 'kmeans'or'ward'
minCluster = 4; % 作成するクラスター数の最小値(シルエット分析の場合のみ)
maxCluster = 15; % 作成するクラスターの最大値

%% 2.d4PDF雨量データの読み込み
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
if doNormalization == 1
    rain = normalize(rain,2,'norm',1);
end

%% 3.適切なクラスター数の検討
switch methodEvaluation
    case 'elbow'
        sse = zeros(1,maxCluster); % クラスター内誤差平方和
        for nCluster = 1:maxCluster
            switch methodClustering
                case 'kmeans' % k-means法
                    idx = kmeans(rain,nCluster,'Start','sample');
                case 'ward' % ward法
                    idx = clusterdata(rain,'Linkage','ward','MaxClust',nCluster);
            end
            centRain = zeros(nCluster,size(rain,2)); % 配列の事前割り当て
            for i = 1:nCluster
                clusRain = rain(idx==i,:); % 同じクラスターの雨をまとめる
                centRain(i,:) = mean(clusRain); % 各クラスターの重心を求める
                for j = 1:size(clusRain,1)
                    sse(nCluster) = sse(nCluster) + ...
                                    norm(clusRain(j,:)-centRain(i,:))^2;
                end
            end
            % sse(nCluster) = sse(nCluster)/nCluster;
        end
        figure
        plot(sse,'-^','LineWidth',1)
        % xlim([0 31])
        % xticks(0:6:30)
        % ylim([100 350])
        xlabel('Number of Cluster')
        ylabel('SSE')
        fontsize(14,"points")

    case 'silhouette'
        for nCluster = minCluster:maxCluster
            switch methodClustering
                case 'kmeans' % k-means法
                    idx = kmeans(rain,nCluster,'Start','sample');
                case 'ward' % ward法
                    idx = clusterdata(rain,'Linkage','ward','MaxClust',nCluster);
            end
            figure
            silhouette(rain,idx)
        end
end