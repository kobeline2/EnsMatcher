function k = decideK(X, cfg)
kpol = lower(string(cfg.kPolicy));

if kpol == "manual"
    k = cfg.k;
    return;
end

kRange = cfg.kRange;
ks = str2double(kRange{1}):str2double(kRange{2});

bestScore = +inf;
bestK = ks(1);
curve = nan(numel(ks),2);

for ii = 1:numel(ks)
    ki = ks(ii);
    idx = runClustering(X, cfg, ki);

    switch kpol
        case "dbi"
            score = daviesBouldinIndex(X, idx, ki);
        case "silhouette"
            s = silhouette(X, idx);
            score = -mean(s); % maximize mean(s) <=> minimize negative
        otherwise
            error("Unknown kPolicy: %s", cfg.kPolicy);
    end

    curve(ii,:) = [ki, score];

    if score < bestScore
        bestScore = score;
        bestK = ki;
    end
end

k = bestK;

% store curve into cfg? -> do not mutate cfg here; return via meta if needed.
end