%% extract nHourRain
pathConfig = 'config/rain_extraction.yaml';
const = getConfig('debug');
cfg = readyaml(pathConfig);
% calcNhourRainD4PDF(cfg, const);
calcNhourRainEns(cfg, const);
% calcNhourRainKaiseki(cfg, const);
%% clustering
pathConfig = 'config/clustering.yaml';
const = getConfig('debug');
cfg = readyaml(pathConfig);
clusteringSpatioTemp(cfg, const)
%% matching
pathConfig = 'config/matching.yaml';
const = getConfig('debug');
cfg = readyaml(pathConfig);
clusteringSpatioTemp(cfg, const)