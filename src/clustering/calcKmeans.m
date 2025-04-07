function [idx, centers, bestK] = calcKmeans(X, cfg)
% myKMeansClustering  多次元データにK-meansクラスタリングを施す
%
% [使い方]
%   [idx, centers, bestK] = myKMeansClustering(X, k, autoCluster)
%
% [入力]
%   X           : N×D の行列（N 個のデータ、各データは D 次元）
%   k           : 希望するクラスタ数 (autoCluster=false のときに使用)
%                 autoCluster=true のときは無視される
%   autoCluster : true にすると、シルエット係数で最適なクラスタ数を探索する
%                 false (または省略) にすると、与えられた k でそのままクラスタリング
%
% [出力]
%   idx     : 各データ点が所属するクラスタ番号 (N×1 ベクトル)
%   centers : 推定された各クラスタの重心（k×D 行列）
%   bestK   : 実際に選ばれたクラスタ数
%
% [備考]
%   autoCluster=true の場合、2 から 10 までのクラスタ数候補を試して
%   シルエット係数を最大にするクラスタ数を bestK として採用します。
%   その後、k-means を bestK で実施して結果を返します。
 
if cfg.random; rng('shuffle'); else; rng(cfg.seed); end

RANGEK_MIN = 2;
RANGEK_MAX = min(20, size(X, 1));
N_REPLICATES = 5;

% % 引数チェック（autoClusterのデフォルトをfalseに）
% if nargin < 3 || isempty(autoCluster)
%     autoCluster = false;
% end

switch cfg.optKmethod
    case "Silhouette"
        rangeK = RANGEK_MIN:RANGEK_MAX;  % 探索範囲に設定
        bestScore = -Inf;
        bestK = NaN;
        
        for tempK = rangeK
            % k-means でクラスタリング（冪等性のため Replicates を指定）
            tempIdx = kmeans(X, tempK, ...
                             'Replicates', N_REPLICATES, ...   % 初期化を複数回試す
                             'Display','off');      % 計算過程の表示をオフ
            
            % シルエット係数を計算して平均をとる
            s = silhouette(X, tempIdx);
            avgSilhouette = mean(s);
            
            % より良いスコアを得たら更新
            if avgSilhouette > bestScore
                bestScore = avgSilhouette;
                bestK = tempK;
            end
        end
        % 探索で見つけた bestK を採用してクラスタリングする
        kToUse = bestK;
    case "manual"
        % autoCluster = false の場合は、ユーザ指定の k をそのまま使う
        bestK  = cfg.nCluster;
        kToUse = cfg.nCluster;
end

% 最終的なクラスタ数 kToUse で k-means クラスタリング
[idx, centers] = kmeans(X, kToUse, ...
    'Replicates', N_REPLICATES, ...
    'Display','off' ...
);
end