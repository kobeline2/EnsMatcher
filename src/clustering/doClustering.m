function [idx, centers, bestK] = doClustering(rain, cfg)


switch cfg.method
    case 'kmeans' % k-means法
        [idx, centers, bestK] = calcKmeans(rain, cfg);
        
    case 'ward' % ウォード法(テンドログラムを描画する)
        idx = calcWard(rain, cfg);
        % % オブジェクト間のユークリッド距離を計算
        % euclid = pdist(rain);
        % % 近接するオブジェクトのペアをリンク(ウォード法)
        % link = linkage(euclid,"ward");
        % % デンドログラムを描画
        % figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        % dendrogram(link,size(rain,1))
        % % 作成するクラスターの数を指定
        % idx = cluster(link,"maxclust",cfg.nCluster);
    case 'cos' % コサイン類似度
         idx = calcCosine(rain, cfg);
        % cos = pdist(rain,'cosine');
        % link = linkage(cos,'complete'); % 完全連結法
        % figure('Position',[500 200 900 500]) % 3列目が幅，4列目が高さ
        % dendrogram(link,size(rain,1))
        % idx = cluster(link,'maxclust',cfg.nCluster);
        % % idx = clusterdata(rain,'Distance','cosine','Linkage','average','Maxclust',cfg.nCluster);
end
end
