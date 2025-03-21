%%% アメダスとアンサンブルをd4PDFのクラスターに振り分ける(空間分布) %%%

%% 1.パラメータの設定
clusteringResultPath = ['\\10.244.3.104\homes\アンサンブル予測\Result\' ...
                        'miya\72hours\clustering\spatial\' ...
                        'miya_clustering_spatial_5.mat'];
load(clusteringResultPath)
basin = 'miya'; % 流域
startY = 2017; % 対象期間の開始年
startM = 10; % 対象期間の開始月
startD = 20; % 対象期間の開始日
startH = 9; % 対象期間の開始時(9 or 21)
% アメダス雨量の寄与率のMATファイル
amedasFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                      'ProcessedRain','contributionRatio','amedas', ...
                      basin,sprintf('%dhours',h), ...
                      sprintf('%s_%04d%02d%02d%02d00.mat', ...
                              basin,startY,startM,startD,startH));
load(amedasFile)
% アンサンブル雨量の寄与率のMATファイル
ensFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'ProcessedRain','contributionRatio','ensemble', ...
                   basin,sprintf('%dhours',h), ...
                   sprintf('%s_%04d%02d%02d%02d00.mat', ...
                           basin,startY,startM,startD,startH));
load(ensFile)
methodMatching = 'euclid'; % 'euclid','ward'or'cos'
% マッチング結果(画像)を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'Result',basin,sprintf('%dhours',h),'matching','spatial', ...
                   sprintf('%s_%04d%02d%02d%02d00_%s.png', ...
                           basin,startY,startM,startD,startH,methodMatching));

%% 2.アメダス雨量の読み込み + 分類 + Nash係数を計算
d    = zeros(1, nCluster); % distance
nash = zeros(1,nCluster); % Nash係数

% クラスターに分類
for i = 1:nCluster
    switch methodMatching
        case 'euclid' % (1)ユークリッド距離
            % d4PDFの各クラスターの重心とアンサンブルの間のユークリッド距離を計算
            d(i) = norm(meanRatio(i,:)-amedasX); 
        case 'ward' % (2)ウォード法
            % d4PDFの各クラスターの重心とアンサンブルの間の距離をウォード法で計算
            d(i) = sqrt((2*nnz(idx==i))/(1+nnz(idx==i)))...
                   *norm(meanRatio(i,:)- amedasX);
        case 'cos' % (3)コサイン類似度
            % d4PDFの各クラスターの重心とアンサンブルが作る角度の余弦を計算
            d(i) = -cos(subspace(meanRatio(i,:)',amedasX'));
    end
    % Nash係数
    NUM = norm(amedasX-meanRatio(i,:)')^2; % 分子
    DEN = norm(amedasX-mean(amedasX))^2; % 分母
    nash(i) = 1 - NUM/DEN; % Nash係数を計算
end
[~,amedasIdx] = min(d); % アメダスが分類されたクラスター番号を取得

%% 3.アンサンブル雨量の読み込み + 分類
% 初期時刻を対象期間の開始時刻に設定
Y = startY;
M = startM;
D = startD;
H = startH;
tmpDate = datetime(Y, M, D, H, 00, 00);

nWindow = 15*2-h/12+1;
d       = zeros(1, nCluster); % distance
ensIdx  = zeros(1, 51);
nMember = zeros(nCluster, nWindow);

for initTimeNum = 1:nWindow % 初期時刻    
    for mem = 1:51 % アンサンブル予測のメンバー(通常はmem = 1:51)   
        for i = 1:nCluster
            switch methodMatching
                case 'euclid' % (1)ユークリッド距離
                    % d4PDFの各クラスターの重心とアンサンブルの間のユークリッド距離を計算
                    d(i) = norm(meanRatio(i,:)-ensX((initTimeNum-1)*51+mem,:)); 
                case 'ward' % (2)ウォード法
                    % d4PDFの各クラスターの重心とアンサンブルの間の距離をウォード法で計算
                    d(i) = sqrt((2*nnz(idx==i))/(1+nnz(idx==i)))...
                           *norm(meanRatio(i,:)- ensX((initTimeNum-1)*51+mem,:));
                case 'cos' % (3)コサイン類似度
                    % d4PDFの各クラスターの重心とアンサンブルが作る角度の余弦を計算
                    d(i) = -cos(subspace(meanRatio(i,:)',ensX((initTimeNum-1)*51+mem,:)'));
            end
        end
        % アンサンブルが分類されたクラスター番号を取得
        [~, ensIdx(mem)] = min(d); 
    end
    % 各クラスターに分類されたメンバー数を格納
    for i = 1:nCluster
        nMember(i, nWindow+1-initTimeNum) = nnz(ensIdx==i); 
    end

    % 初期時刻の更新(-12hours)
    tmpDate(initTimeNum+1) = tmpDate(initTimeNum) - hours(12);
end

%% 4.ヒートマップの作成
tmpDate.Format = 'MM/dd HH';

% ヒートマップの作成(large)
figure('Position',[300 200 900 29*nCluster+102]) % 3列目が幅，4列目が高さ
heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
heat.XLabel = 'Initial Time';
heat.YLabel = 'Cluster Number';
heat.XDisplayLabels = flip(char(tmpDate(1:end-1)));
heat.FontSize = 14;
saveas(gcf,outFile) % 画像を保存

% ヒートマップの作成(small)
figure('Position',[1300 200 500 16*nCluster+58]) % 3列目が幅，4列目が高さ
heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
heat.XLabel = 'Initial Time';
heat.YLabel = 'Cluster Number';
heat.XDisplayLabels = flip(char(tmpDate(1:end-1)));
heat.FontSize = 8;