function clusteringSpatioTemp(cfg, const)
%%% d4PDFの時空間分布のクラスタリング %%%

%% 1.パラメータの設定
nHourRain = cfg.nHourRain;
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
nHourRainDir = fullfile(const.path.outNhourRain, ...
                        'd4pdf', ...
                        cfg.basin, ...
                        sprintf('%dhours', nHourRain));
fnFmt = '*.dat'; % 読み込みたい雨量データのファイル名
% 変数を保存するMATファイル
dirOut = fullfile(const.path.outClustered, cfg.basin, 'spatioTemp', ...
                      sprintf('%dhours', nHourRain));
fnOut = sprintf('%s%d_%s', cfg.method, cfg.nCluster, cfg.optKmethod);
                         
%% 2.ティーセン分割後の各領域のid(番号)を取得
[~, ~, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCell = length(idD4pdfcell);

%% 3.d4PDF雨量データの読み込み
% rainのサイズは, (ランク数×アンサンブル数)×(セル数×nHourRain)
for iRank = 1:cfg.maxRank  
    FnList = dir(fullfile(nHourRainDir, num2str(iRank), fnFmt));
    nDatFile = length(FnList);
    tmpRain = zeros(nDatFile, nCell*nHourRain);
    for i = 1:nDatFile
        tmpRain(i,:) = reshape(readmatrix(fullfile(FnList(i).folder, ...
                                                    FnList(i).name)), ...
                                [1, nCell*nHourRain]);
    end
    if iRank == 1; rain = zeros(nDatFile*cfg.maxRank , nCell*nHourRain); end
    rain(nDatFile*(iRank-1)+1:nDatFile*iRank, :) = tmpRain;
end

%% クラスタリング
% rainのサイズは, (cluster数)×(セル数×nHourRain)
% bestKはcfgでクラスター数の自動選択を選んだときに有意
[idx, centers, bestK] = doClustering(rain, cfg);
cfg.bestK = bestK;

%% 6.各クラスターの流域総雨量を計算して，少ない順にクラスター番号を再度割り振る
rowSums = sum(centers, 2);              % 各行の合計を計算（1行ごとに列を足す）
[~, idxTmp] = sort(rowSums, 'ascend');  % 合計が昇順になるように並べ替えるためのインデックスを取得
centers = centers(idxTmp, :);           % そのインデックスに基づいて行を並べ替え
% ワークスペースの変数を保存
writeMatrixToDir(centers', dirOut, strcat(fnOut, '.dat'));
outputCfgAsJson(strcat(fnOut, '.json'), dirOut, cfg)

%% 動画作成, 保存
if cfg.makeMovie
    % 各クラスターに分類されたrainの個数を取得
    nPerCluster = zeros(1,cfg.nCluster); % 配列の事前割り当て
    for iCluster = 1:cfg.nCluster
        nPerCluster(iCluster) = nnz(idx==iCluster);
    end
    % d4PDFの計算点の緯度経度を取得
    fn = fullfile(const.path.d4pdf, 'cnst', 'location.csv');
    tmp = readmatrix(fn, "NumHeaderLines", 1);
    lonD4pdf = tmp(idD4pdfcell, 5); % 経度
    latD4pdf = tmp(idD4pdfcell, 4); % 緯度
    outMovieFile = fullfile(const.path.outClustered, ...
                            cfg.basin, ...
                            sprintf('%dhours', nHourRain), ...
                            'clustering', 'both', ...
                            sprintf('%s_clustering_both_%d_%s.mp4', ...
                                    cfg.basin,cfg.nCluster,cfg.method));
    saveMovieClustered(outMovieFile)
end
end

