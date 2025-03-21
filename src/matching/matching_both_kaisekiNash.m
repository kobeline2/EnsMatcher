%{
解析雨量とアンサンブルをd4PDFのクラスターに振り分ける(時空間分布)
euclidにはNash係数の，cosにはΘのフィルターを設定
%}

%% 1.パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basin = 'chikugo'; % 流域
h = 72; % 対象期間(hours)
clusteringMethod = 'ward'; % 'kmeans','ward'or'cos'
nCluster = 6; % クラスターの数
matchingMethod = 'euclid'; % 'euclid'or'cos'
useFilter = 1; % filterを設定するか(1or0)

% 対象期間の開始時刻["yyyyMMddHHmm","yyyyMMddHHmm"]
targetTimeSet = ["201707040900","201807042100","202108112100","202209162100"];

% clustering結果のmatファイル
clusteringResult = fullfile(projectFolder,'Result',basin, ...
                            sprintf('%dhours',h),'clustering','both', ...
                            sprintf('%s_clustering_both_%d_%s.mat', ...
                                    basin,nCluster,clusteringMethod));
% 解析雨量のRainMatrixのフォルダ
kaisekiRainMatrixFolder = fullfile(projectFolder,'ProcessedRain', ...
                                   'rainMatrix','kaiseki', ...
                                   basin,sprintf('%dhours',h));
% アンサンブル予測のcsvファイルがあるフォルダ(basinのものであれば何でも良い)
ensFolder = fullfile(projectFolder,'ensemble',basin);
% アンサンブル予測のRainMatrixがあるフォルダ
ensRainMatrixFolder = fullfile(projectFolder,'ProcessedRain','rainMatrix', ...
                               'ensemble',basin,sprintf('%dhours',h));
% d4PDF計算点の支配領域面積のデータがあるファイル
d4pdfAreaFile = fullfile(projectFolder,'geoData',basin, ...
                         sprintf('%s_area_per_d4pdfcell.csv',basin));
% d4PDFの計算点の緯度経度の情報が入ったcsvファイル
d4pdfLocationFile = fullfile(projectFolder,'d4PDF','d4PDF_5kmDDS_JP', ...
                             'cnst','location.csv');
% % マッチング結果(画像)を出力するフォルダ
% outFolder = fullfile(projectFolder,'Result',basin,sprintf('%dhours',h), ...
%                      'matching','both');
% switch useFilter
%     case 1
%         outFolder = fullfile(outFolder,sprintf('%dclusters_filter',nCluster));
%     case 0
%         outFolder = fullfile(outFolder,sprintf('%dclusters',nCluster));
%     otherwise
%         error('useFilter must be 1 or 0')
% end
% % 平均的中率と各初期時刻の正解メンバー数を出力するファイル
% accuracyFile = fullfile(outFolder,sprintf('accuracy_%s.dat',matchingMethod));


%% 2.clustering結果の読み込み
load(clusteringResult)


%%
% fileID = fopen(accuracyFile,'w');
nWindow = 15*2-h/12+1; % 初期時刻の数
ensNash = zeros(51, nWindow,numel(targetTimeSet)); % ensembleのNash係数
kaisekiNash = zeros(nCluster,numel(targetTimeSet)); % 解析雨量のNash係数
for iTargetTime = 1:numel(targetTimeSet)
    targetTime = targetTimeSet(iTargetTime);
    
    %% 3.解析雨量のrainMatrixの読み込み → matching → Nash係数を計算
    d = zeros(1,nCluster); % distance
    
    % 解析雨量のrainMatrix読み込み
    kaisekiRain = readmatrix(fullfile(kaisekiRainMatrixFolder, ...
                             sprintf('%s_%s.dat',basin,targetTime)));
    kaisekiRain = reshape(kaisekiRain,[1,numel(kaisekiRain)]);
    
    % クラスターに分類
    for i = 1:nCluster
        switch matchingMethod
            case 'euclid' % (1)ユークリッド距離
                % d4PDFの各クラスターの重心とアメダスの間のユークリッド距離を計算
                d(i) = norm(centRain(i,:)-kaisekiRain);
            case 'cos' % (2)コサイン類似度
                % d4PDFの各クラスターの重心とアメダスが作る角度の余弦を計算
                d(i) = -cos(subspace(centRain(i,:)',kaisekiRain'));
        end
        % Nash係数
        NUM = norm(kaisekiRain-centRain(i,:))^2; % 分子
        DEN = norm(kaisekiRain-mean(kaisekiRain))^2; % 分母
        kaisekiNash(i,iTargetTime) = 1 - NUM/DEN; % Nash係数を計算
    end
    [~,kaisekiIdx] = min(d); % 解析雨量が分類されたクラスター番号を取得
    
    % (総雨量0mm && コサイン類似度) のときはマッチングさせない
    if sum(kaisekiRain) == 0 && strcmp(matchingMethod,'cos') == 1
        kaisekiIdx = 0;
    end
    
    
    %% 4.アンサンブル予測のグリッドの経度緯度を取得(ensembleのresamplingの準備)
    ensData = readmatrix(fullfile(ensFolder,sprintf('%s_01.csv',targetTime)), ...
                         'NumHeaderLines',0,'Delimiter',',');
    ROW     = ensData(1,13); % アンサンブル予測のグリッドの行数
    COL     = ensData(1,12); % アンサンブル予測のグリッドの列数
    west    = ensData(1,14); % 最西端の経度
    east    = ensData(1,16); % 最東端の経度
    north   = ensData(1,15); % 最北端の緯度
    south   = ensData(1,17); % 最南端の緯度
    dx      = 0.0625;        % x(経度)方向のグリッドの間隔
    dy      = 0.05;          % y(緯度)方向のグリッドの間隔
    
    % アンサンブルメッシュの中心の経度緯度
    [ensLon,ensLat] = meshgrid(west +dx/2 : dx : east -dx/2, ...
                               north-dy/2 :-dy : south+dy/2);
    
    
    %% 5.d4PDFの計算点の緯度経度を取得(ensembleのresamplingの準備)
    % basinを覆う計算点の番号を取得
    d4pdfAreaData = readmatrix(d4pdfAreaFile,"NumHeaderLines",1);
    id = d4pdfAreaData(:,1); % 通し番号
    
    % 計算点の緯度経度を取得
    d4pdfLocationData = readmatrix(d4pdfLocationFile,"NumHeaderLines",1);
    d4pdfLon = d4pdfLocationData(id,5); % 経度
    d4pdfLat = d4pdfLocationData(id,4); % 緯度
    
    
    %% 6.ensembleのrainMatrixの読み込み → resampling → matching
    % 初期時刻を対象期間の開始時刻に設定
    initTime = datetime(targetTime,'InputFormat','yyyyMMddHHmm');
    initTime.Format = 'yyyyMMddHHmm';
    d       = zeros(1, nCluster); % distance
    ensIdx  = zeros(1, 51);
    
    nMember = zeros(nCluster, nWindow);
    
    for initTimeNum = 1:nWindow % 初期時刻
        for mem = 1:51 % アンサンブル予測のメンバー(通常はmem = 1:51)
    
            % rainMatrixの読み込み
            rainMatrix = readmatrix(fullfile(ensRainMatrixFolder,targetTime, ...
                                             sprintf('%s_%s_%03d.dat', ...
                                                     basin,initTime(initTimeNum),mem)));
    
            % resampling
            for time = 1:h
                ensRain = reshape(rainMatrix(:,time),[ROW,COL]);
                nCol = (time-1)*length(id); % 経過時間×d4PDFの計算点の数
                reEnsRain(nCol+1:nCol+length(id)) ...
                = interp2(ensLon,ensLat,ensRain,d4pdfLon,d4pdfLat);
            end
    
            % matching
            for i = 1:nCluster
                switch matchingMethod
                    case 'euclid' % (1)ユークリッド距離
                        % d4PDFの各クラスターの重心とアンサンブルの間のユークリッド距離を計算
                        d(i) = norm(centRain(i,:)-reEnsRain); 
                    case 'cos' % (2)コサイン類似度
                        % d4PDFの各クラスターの重心とアンサンブルが作る角度の余弦を計算
                        d(i) = -cos(subspace(centRain(i,:)',reEnsRain'));
                end
            end
            % アンサンブルが分類されたクラスター番号を取得
            [~, ensIdx(mem)] = min(d);
            % filter
            if useFilter==1
                % Nash係数を計算
                NUM = norm(reEnsRain-centRain(ensIdx(mem),:))^2; % 分子
                DEN = norm(reEnsRain-mean(reEnsRain))^2; % 分母
                ensNash(mem,nWindow+1-initTimeNum,iTargetTime) = 1 - NUM/DEN;
                % (NS<0 && ユークリッド距離) のときはマッチングさせない
                if ensNash(mem,nWindow+1-initTimeNum,iTargetTime) < 0 && ...
                   strcmp(matchingMethod,'euclid') == 1
                    ensIdx(mem) = 0;
                % (Θ>60° && コサイン類似度) のときはマッチングさせない
                elseif -min(d) < cosd(60) && strcmp(matchingMethod,'cos') == 1
                    ensIdx(mem) = 0;
                end
            end
            % (総雨量0mm && コサイン類似度) のときはマッチングさせない
            if sum(reEnsRain) == 0 && strcmp(matchingMethod,'cos') == 1
                ensIdx(mem) = 0;
            end

        end
        % 各クラスターに分類されたメンバー数を格納
        for i = 1:nCluster
            nMember(i, nWindow+1-initTimeNum) = nnz(ensIdx==i); 
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
    endTime = startTime + hours(h);
    endTime.Format = 'MM/dd HH:mm'; % 対象期間の終了時刻
    heat.Title = sprintf('Target period: %s - %s',startTime,endTime);
    %%%

    heat.FontSize = 14;
    heatmapStruct = struct(heat);
    heatmapStruct.Colorbar.Ticks = (0:10:50);
    fig.Color = 'none';
    fig.InvertHardcopy = 'off';
    set(gca,'Fontname','Arial')
    % outFile = fullfile(outFolder,sprintf('%s_%s_%s_%d.svg', ...
    %                                      basin,targetTime,matchingMethod,kaisekiIdx));
    % saveas(fig,outFile) % 画像を保存


    %% 8.的中率の計算
    % 全初期時刻の平均的中率を計算
    % fprintf(fileID,'%s',targetTimeSet(iTargetTime));
    nCorrectMember = sum(nMember(kaisekiIdx,:));
    meanAccuracy = nCorrectMember/(nWindow*51);
    % fprintf(fileID,' %f',meanAccuracy);

    % 各初期時刻における正解のメンバー数を抽出
    nCorrectMember = nMember(kaisekiIdx,:);
    % fprintf(fileID,' %d',nCorrectMember);
    % fprintf(fileID,'\n');


end
% fclose(fileID);

%%
disp(kaisekiNash)