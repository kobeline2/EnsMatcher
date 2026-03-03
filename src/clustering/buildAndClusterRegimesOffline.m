function out = buildAndClusterRegimesOffline(cfg, const)
%BUILDANDCLUSTERREGIMESOFFLINE
%  Reads d4PDF event matrices and constructs offline regimes by clustering.
%
% out fields:
%   .events  : struct with x, raw (optional), prob, mass, info
%   .idx     : [N x 1]
%   .centers : [k x D]
%   .meta    : struct returned from doClustering
%   .cfgOut  : cfg updated with chosen k

% ---- paths ----
nHourRain = cfg.nHourRain;
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
baseDir = fullfile(const.path.outNhourRain, 'd4pdf', cfg.basin, sprintf('%dhours', nHourRain));
dirOut  = fullfile(const.path.outClustered, cfg.basin, 'spatioTemp', sprintf('%dhours', nHourRain));
if ~exist(dirOut, 'dir'); mkdir(dirOut); end

% ---- expected grid size (for sanity) ----
[~, ~, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCell = numel(idD4pdfcell);

% ---- read events ----
events = readEventMatricesFromDir(baseDir, cfg.maxRank, nCell, nHourRain);

% ---- clustering (current paper: Ward etc.) ----
[idx, centers, meta] = doClustering(events.x, cfg);

% ---- chosen k ----
kUsed = size(centers, 1);
if isfield(meta, 'kUsed'); kUsed = meta.kUsed; end
if isfield(meta, 'k');    kUsed = meta.k;    end

% ---- update cfg for outputs ----
cfgOut = cfg;
if isfield(cfgOut, 'nCluster'); cfgOut.nCluster = kUsed; end
if isfield(cfgOut, 'k');        cfgOut.k = kUsed;        end

% ---- output naming (stable) ----
algo = pickField(cfgOut, "algorithm", "clust");
dist = pickField(cfgOut, "distance",  "dist");
link = pickField(cfgOut, "linkage",   "link");
kpol = pickField(cfgOut, "kPolicy",   "kpol");

fnOut = sprintf('%s_%s_%s_k%d_%s', algo, dist, link, kUsed, kpol);

% ---- save ----
% centers: D x k as .dat (your convention)
writeMatrixToDir(centers', dirOut, strcat(fnOut, '.dat'));

% idx/meta/events.info as .mat for reproducibility
save(fullfile(dirOut, strcat(fnOut, '.mat')), 'idx', 'meta', 'events', 'cfgOut', '-v7.3');

% cfg as json
outputCfgAsJson(strcat(fnOut, '.json'), dirOut, cfgOut);

out = struct();
out.events  = events;
out.idx     = idx;
out.centers = centers;
out.meta    = meta;
out.cfgOut  = cfgOut;
end

function s = pickField(cfg, name, fallback)
if isfield(cfg, name)
    s = string(cfg.(name));
else
    % backward compatibility for old keys
    if name=="algorithm" && isfield(cfg,'method'); s = string(cfg.method); return; end
    if name=="kPolicy"   && isfield(cfg,'optKmethod'); s = string(cfg.optKmethod); return; end
    s = string(fallback);
end
end