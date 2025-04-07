function matchingSpatioTemp(cfg, const)
%{
解析雨量とアンサンブルをd4PDFのクラスターに振り分ける(時空間分布)
euclidにはNash係数の，cosにはΘのフィルターを設定
%}

%% 1.パラメータの設定
str = fileread(strcat(cfg.clusteredFilepath(1:end-3), 'json'));
cfgClustered = jsondecode(str);

nHourRain = cfg.nHourRain;
targetTime = num2str(cfg.targetTime);
nCluster = cfgClustered.bestK; % クラスターの数

% 解析雨量のRainMatrixのフォルダ
kaisekiRainMatrixFolder = fullfile(const.path.outNhourRain, ...
                                   'kaiseki', ...
                                   cfg.basin, ...
                                   sprintf('%dhours', nHourRain));

% アンサンブル予測のcsvファイルがあるフォルダ(cfg.basinのものであれば何でも良い)
ensDir = fullfile(const.path.ens, cfg.basin);

% アンサンブル予測のRainMatrixがあるフォルダ
ensRainMatrixFolder = fullfile(const.path.outNhourRain, ...
                               'ens', cfg.basin, ...
                               sprintf('%dhours', nHourRain));

% マッチング結果(画像)を出力するフォルダ
outFolder = fullfile(const.path.outMatched, ...
                     cfg.basin, ...
                     sprintf('%dhours', nHourRain), ...
                     'spatioTemp', ...
                     sprintf('%dclusters_%s', nCluster, cfg.filterMethod));

% 平均的中率と各初期時刻の正解メンバー数を出力するファイル
accuracyFile = fullfile(outFolder, ...
                        sprintf('accuracy_%s.dat', ...
                        cfg.matchingMethod));


%% 2.clustering結果の読み込み
centers = readmatrix(cfg.clusteredFilepath);

%% 3.解析雨量のrainMatrixの読み込み → matching → Nash係数を計算
kaisekiNash = zeros(nCluster); % 解析雨量のNash係数
d = zeros(1, nCluster); % distance
% 解析雨量のrainMatrix読み込み
kaisekiRain = readmatrix(fullfile(kaisekiRainMatrixFolder, sprintf('%s.dat', targetTime)));
kaisekiRain = kaisekiRain(:);

% クラスターに分類
for iCluster = 1:nCluster
    d(iCluster) ...
        = caclDistanceBetweenRains(centers(:, iCluster), kaisekiRain, cfg.matchingMethod);
    kaisekiNash(iCluster) = calcNash(kaisekiRain, centers(:, iCluster));
end
[~, kaisekiIdx] = min(d); % 解析雨量が分類されたクラスター番号を取得

% (総雨量0mm && コサイン類似度) のときはマッチングさせない
if sum(kaisekiRain) == 0 && strcmp(cfg.matchingMethod, 'cos') == 1
    kaisekiIdx = 0;
end


%% 4.アンサンブル予測, d4PDFのグリッドの経度緯度を取得(ensembleのresamplingの準備)
fn = fullfile(ensDir,sprintf('%s_01.csv', targetTime));
[ensLon, ensLat, ROW, COL] = fetchBasinGridEns(fn);
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
F = griddedInterpolant(ensLon, ensLat, zeros(size(ensLon)), 'linear'); 


%% 6.ensembleのrainMatrixの読み込み → resampling → matching
nWindow = const.leadtimeEns/0.5 - nHourRain/12 + 1; % 初期時刻の数
ensNash = zeros(const.nEns, nWindow); % ensembleのNash係数
% 初期時刻を対象期間の開始時刻に設定
initTime = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
initTime.Format = 'yyyyMMddHHmm';
d       = zeros(1, nCluster); % distance
ensIdx  = zeros(1, const.nEns);

nMember = zeros(nCluster, nWindow);

for initTimeNum = 1:nWindow % 初期時刻
    for iMember = 1:const.nEns % アンサンブル予測のメンバー(通常はmem = 1:51)

        % rainMatrixの読み込み
        rainMatrix = readmatrix(fullfile(ensRainMatrixFolder,targetTime, ...
                                         sprintf('%s_%03d.dat', ...
                                                 initTime(initTimeNum), iMember)));
        % resampling
        for time = 1:nHourRain
            ensRain = reshape(rainMatrix(:, time), [ROW, COL]);
            nCol = (time-1) * length(id); % 経過時間×d4PDFの計算点の数
            F.Values = ensRain;  
            reEnsRain(nCol+1:nCol+length(id)) = F(lonD4pdf, latD4pdf);
                        % = interp2(ensLon, ensLat, ensRain, d4pdfLon, d4pdfLat);
        end

        % matching
        for iCluster = 1:nCluster
        d(iCluster) ...
             = caclDistanceBetweenRains(centers(:, iCluster), reEnsRain, cfg.matchingMethod);
        end
        % アンサンブルが分類されたクラスター番号を取得
        [~, ensIdx(iMember)] = min(d);
        % Nash係数を計算
        ensNash(iMember,nWindow+1-initTimeNum) = calcNash(reEnsRain, centers(ensIdx(iMember)));

        % filter
        nash = ensNash(iMember,nWindow+1-initTimeNum);
        ensIdx(iMember) = doFilterindoFiltering(cfg, idx, nash, d);

        % (総雨量0mm && コサイン類似度) のときはマッチングさせない
        if sum(reEnsRain) == 0 && strcmp(cfg.matchingMethod, 'cos') == 1
            ensIdx(iMember) = 0;
        end

    end
    % 各クラスターに分類されたメンバー数を格納
    for iCluster = 1:nCluster
        nMember(iCluster, nWindow+1-initTimeNum) = nnz(ensIdx==iCluster); 
    end
    % 初期時刻の更新(-12hours)
    initTime(initTimeNum+1) = initTime(initTimeNum) - hours(12);
end


%% 7.ヒートマップの作成
% 日時ベクトルの作成
initTime.Format = 'MM/dd HH';

% ヒートマップの作成(large)
%%%
% (1)xLabelが月日時
% fig = figure('Position',[300 200 900 29*nCluster+102]); % 3列目が幅，4列目が高さ
% heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
% heat.XLabel = 'Initial time of ensemble forecast';
% heat.YLabel = 'Cluster number';
% heat.XDisplayLabels = flip(char(initTime(1:end-1)));
%%%

%%%
% (2)xLabelがリードタイム
fig = figure('Position',[300 200 1100 30*nCluster+102]);
heat = heatmap(nMember,"Colormap",jet,"ColorLimits",[0 51]);
heat.XLabel = 'Lead time of ensemble forecast [day]';
heat.YLabel = 'Cluster number';
maxLT = (nWindow-1)/2; % アンサンブルの最大リードタイム（日）
customXLabel = string(maxLT:-0.5:0);
customXLabel(mod((1:nWindow),6) ~= 1) = "";
heat.XDisplayLabels = customXLabel;
startTime = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
startTime.Format = 'yyyy/MM/dd HH:mm'; % 対象期間の開始時刻
endTime = startTime + hours(nHourRain);
endTime.Format = 'MM/dd HH:mm'; % 対象期間の終了時刻
heat.Title = sprintf('Target period: %s - %s',startTime,endTime);
%%%

heat.FontSize = 14;
heatmapStruct = struct(heat);
heatmapStruct.Colorbar.Ticks = (0:10:50);
fig.Color = 'none';
fig.InvertHardcopy = 'off';
set(gca,'Fontname','Arial')
outFile = fullfile(outFolder,sprintf('%s_%s_%d.svg', ...
                                     targetTime, ...
                                     cfg.matchingMethod, ...
                                     kaisekiIdx));
saveas(fig, outFile) % 画像を保存
% 
% 
% %% 8.的中率の計算
% % 全初期時刻の平均的中率を計算
% fid = fopen(accuracyFile,'w');
% nCorrectMember = sum(nMember(kaisekiIdx,:));
% meanAccuracy = nCorrectMember/(nWindow*51);
% fprintf(fid,' %f',meanAccuracy);
% 
% % 各初期時刻における正解のメンバー数を抽出
% nCorrectMember = nMember(kaisekiIdx,:);
% fprintf(fid,' %d',nCorrectMember);
% fprintf(fid,'\n');
% fclose(fid);
end