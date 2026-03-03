function validateCfg(cfg)
req = ["algorithm","distance","kPolicy"];
for f = req
    if ~isfield(cfg, f)
        error("cfg.%s is required.", f);
    end
end

algo = lower(string(cfg.algorithm));
dist = lower(string(cfg.distance));
kpol = lower(string(cfg.kPolicy));

if algo == "hierarchical"
    if ~isfield(cfg,"linkage"); cfg.linkage = "ward"; end
    link = lower(string(cfg.linkage));

    if link == "ward" && dist ~= "euclidean"
        error("Ward linkage requires Euclidean distance. Got distance=%s", dist);
    end
elseif algo == "kmeans"
    if dist ~= "euclidean"
        error("kmeans requires Euclidean distance. Got distance=%s", dist);
    end
end

if kpol == "manual"
    if ~isfield(cfg,"k")
        error("kPolicy=manual requires cfg.k.");
    end
else
    if ~isfield(cfg,"kRange")
        error("kPolicy ~= manual requires cfg.kRange.");
    end
end
end