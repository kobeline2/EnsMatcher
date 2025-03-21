%%% アメダスとアンサンブルをd4PDFのクラスターに振り分ける(時間分布) %%%

%% 1.パラメータの設定
clusteringResultPath = ['\\10.244.3.104\homes\アンサンブル予測\Result\' ...
                        'miya\72hours\clustering\time\' ...
                        'miya_clustering_time_12_no.mat'];
load(clusteringResultPath)
basin = 'miya'; % 流域
startY = 2017; % 対象期間の開始年
startM = 10; % 対象期間の開始月
startD = 20; % 対象期間の開始日
startH = 9; % 対象期間の開始時(9 or 21)
% アメダス雨量のファイル
amedasFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                      'ProcessedRain','nHoursRain','amedas', ...
                      basin,sprintf('%dhours',h), ...
                      sprintf('%s_%04d%02d%02d%02d00.dat', ...
                              basin,startY,startM,startD,startH));
% アンサンブル雨量のデータがあるフォルダ
ensFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                     'ProcessedRain','nHoursRain','ensemble', ...
                     basin,sprintf('%dhours',h), ...
                     sprintf('%04d%02d%02d%02d00',startY,startM,startD,startH));
movingMean = 'no'; % 移動平均をとるか('yes'or'no')
methodMatching = 'cos'; % 'euclid','ward'or'cos'
useThreshold = 'no'; % 総雨量の閾値でフィルターをかけるか('yes'or'no')
% 総雨量の閾値のデータファイルのパス
thresholdPath = ['\\10.244.3.104\homes\アンサンブル予測\' ...
                 'ProcessedRain\nHoursRain\d4pdf\threshold.dat'];
% マッチング結果(画像)を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'Result',basin,sprintf('%dhours',h),'matching','time', ...
                   sprintf('%s_%04d%02d%02d%02d00_%s.png', ...
                           basin,startY,startM,startD,startH,methodMatching));

%% 2.アメダス雨量の読み込み + 分類 + Nash係数を計算
d = zeros(1,nCluster); % distance
nash = zeros(1,nCluster); % Nash係数

% アメダス雨量の読み込み
amedasRain = readmatrix(amedasFile);

% 正規化
if strcmp(doNormalization,'yes') == 1 && sum(amedasRain) ~= 0
    amedasRain = normalize(amedasRain,'norm',1);
end

% 移動平均
if strcmp(movingMean,'yes') == 1
    amedasRain = movmean(amedasRain,3);
end

% クラスターに分類
for i = 1:nCluster
    switch methodMatching
        case 'euclid' % (1)ユークリッド距離
            % d4PDFの各クラスターの重心とアメダスの間のユークリッド距離を計算
            d(i) = norm(centRain(i,:)'-amedasRain);
        case 'ward' % (2)ウォード法
            % d4PDFの各クラスターの重心とアメダスの間の距離をウォード法で計算
            d(i) = sqrt((2*nnz(idx==i))/(1+nnz(idx==i)))*norm(centRain(i,:)'-amedasRain);
        case 'cos' % (3)コサイン類似度
            % d4PDFの各クラスターの重心とアメダスが作る角度の余弦を計算
            d(i) = -cos(subspace(centRain(i,:)',amedasRain));
            % d(i) = -cos(dot(centRain(i,:)',amedasRain)/(norm(centRain(i,:)')*norm(amedasRain)));
    end
    % Nash係数
    NUM = norm(amedasRain-centRain(i,:)')^2; % 分子
    DEN = norm(amedasRain-mean(amedasRain))^2; % 分母
    nash(i) = 1 - NUM/DEN; % Nash係数を計算
end
[~,amedasIdx] = min(d); % アメダスが分類されたクラスター番号を取得

% (総雨量0mm&&正規化あり)or(総雨量0mm&&正規化なし&&コサイン類似度)
% のときはマッチングさせない
if sum(amedasRain) == 0
    if strcmp(doNormalization,'yes') == 1
        amedasIdx = 0;
    elseif strcmp(doNormalization,'no') == 1 && strcmp(methodMatching,'cos') == 1
        amedasIdx = 0;
    end
end

%% 3.総雨量の閾値の読み込み
if strcmp(useThreshold,'yes') == 1
    fileID = fopen(thresholdPath,'r');
    formatSpec = '%s %f';
    data = textscan(fileID,formatSpec);
    thresholdBasin = string(data{1});
    threshold = data{2}(thresholdBasin == basin);
end

%% 4.アンサンブル雨量の読み込み + 分類
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
    % 初期時刻の文字列の作成
    initTime = sprintf('%04d%02d%02d%02d00', Y, M, D, H);
    
    for mem = 1:51 % アンサンブル予測のメンバー(通常はmem = 1:51)   
        fn = fullfile(ensFolder,...
                      sprintf('%s_%s_%03d.dat', basin, initTime, mem));
        ensRain = readmatrix(fn); % アンサンブル雨量の読み込み
        totalRain = sum(ensRain); % 総雨量
        % 正規化
        if strcmp(doNormalization,'yes') == 1 && totalRain ~= 0
            ensRain = normalize(ensRain,'norm',1);
        end
        % 移動平均
        if strcmp(movingMean,'yes') == 1
            ensRain = movmean(ensRain,3);
        end
        for i = 1:nCluster
            switch methodMatching
                case 'euclid' % (1)ユークリッド距離
                    % d4PDFの各クラスターの重心とアンサンブルの間のユークリッド距離を計算
                    d(i) = norm(centRain(i,:)'-ensRain); 
                case 'ward' % (2)ウォード法
                    % d4PDFの各クラスターの重心とアンサンブルの間の距離をウォード法で計算
                    d(i) = sqrt((2*nnz(idx==i))/(1+nnz(idx==i)))*norm(centRain(i,:)'- ensRain);
                case 'cos' % (3)コサイン類似度
                    % d4PDFの各クラスターの重心とアンサンブルが作る角度の余弦を計算
                    d(i) = -cos(subspace(centRain(i,:)',ensRain));
            end
        end
        % アンサンブルが分類されたクラスター番号を取得
        [~, ensIdx(mem)] = min(d); 
        % (総雨量0mm&&正規化あり)or(総雨量0mm&&正規化なし&&コサイン類似度)
        % のときはマッチングさせない
        if totalRain == 0
            if strcmp(doNormalization,'yes') == 1
                ensIdx(mem) = 0;
            elseif strcmp(doNormalization,'no') == 1 && strcmp(methodMatching,'cos') == 1
                ensIdx(mem) = 0;
            end
        end
        % 総雨量<閾値のときはマッチングさせない
        if strcmp(useThreshold,'yes') == 1 && totalRain < threshold
            ensIdx(mem) = 0;
        end
    end
    % 各クラスターに分類されたメンバー数を格納
    for i = 1:nCluster
        nMember(i, nWindow+1-initTimeNum) = nnz(ensIdx==i); 
    end

    % 初期時刻の更新(-12hours)
    tmpDate(initTimeNum+1) = tmpDate(initTimeNum) - hours(12);
    Y = tmpDate(initTimeNum+1).Year;
    M = tmpDate(initTimeNum+1).Month;
    D = tmpDate(initTimeNum+1).Day;
    H = tmpDate(initTimeNum+1).Hour;
end

%% 5.ヒートマップの作成
% 日時ベクトルの作成
tmpDate.Format = 'MM/dd HH';

% ヒートマップの作成(large)
figure('Position',[300 200 900 29*nCluster+102]); % 3列目が幅，4列目が高さ
heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
heat.XLabel = 'Initial Time';
heat.YLabel = 'Cluster Number';
heat.XDisplayLabels = flip(char(tmpDate(1:end-1)));
heat.FontSize = 14;
saveas(gcf,outFile) % 画像を保存

% ヒートマップの作成(small)
figure('Position',[1300 200 500 16*nCluster+58]); % 3列目が幅，4列目が高さ
heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
heat.XLabel = 'Initial Time';
heat.YLabel = 'Cluster Number';
heat.XDisplayLabels = flip(char(tmpDate(1:end-1)));
heat.FontSize = 8;