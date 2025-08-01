%% extract nHourRain
pathConfig = 'config/rain_extraction.yaml';
const = getConfig('debug');
cfg = readyaml(pathConfig);
% tic; calcNhourRainD4PDF(cfg, const); toc;
tic; calcNhourRainEns(cfg, const); toc; 
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