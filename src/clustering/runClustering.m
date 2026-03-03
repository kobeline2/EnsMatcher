function idx = runClustering(X, cfg, k)
algo = lower(string(cfg.algorithm));
dist = lower(string(cfg.distance));

switch algo
    case "hierarchical"
        link = lower(string(cfg.linkage));

        if link == "ward"
            % Ward: pass observations matrix X
            Z = linkage(X, "ward");
            idx = cluster(Z, "MaxClust", k);
        else
            % other linkage: compute distance vector
            d = pdist(X, dist);
            Z = linkage(d, link);
            idx = cluster(Z, "MaxClust", k);
        end

    case "kmeans"
        if ~isfield(cfg,"replicates"); cfg.replicates = 20; end
        if ~isfield(cfg,"maxIter");    cfg.maxIter = 1000; end
        idx = kmeans(X, k, "Start","plus", "Replicates",cfg.replicates, "MaxIter",cfg.maxIter);

    otherwise
        error("Unknown algorithm: %s", cfg.algorithm);
end
end