function [idx, centers, meta] = doClustering(X, cfg)
%DOCLUSTERING Offline regime construction by clustering.
%   X: [Nevent x D] where D = nCell*nHourRain
%   cfg fields (recommended):
%     cfg.algorithm = "hierarchical" | "kmeans" | "kmedoids"(optional)
%     cfg.distance  = "euclidean" | "cosine" | ...
%     cfg.linkage   = "ward" | "average" | "complete"   (hierarchical only)
%     cfg.kPolicy   = "manual" | "dbi" | "silhouette"
%     cfg.k         = scalar (used when manual)
%     cfg.kRange    = [kmin kmax] (used when kPolicy ~= manual)
%     cfg.reorder   = "templateSum" | "none"

validateCfg(cfg);

% 1) decide k
k = decideK(X, cfg);

% 2) clustering -> idx
idx = runClustering(X, cfg, k);

% 3) centers(template)
centers = computeCenters(X, idx, k);

% 4) reorder clusters if needed (and relabel idx accordingly)
orderOld = (1:k).';
if ~isfield(cfg, "reorder") || lower(string(cfg.reorder)) == "templatesum"
    [centers, idx, orderOld] = reorderByTemplateSum(centers, idx);
end

% meta
meta = struct();
meta.k = k;
meta.orderOldToNew = orderOld;
meta.cfg = cfg;
end