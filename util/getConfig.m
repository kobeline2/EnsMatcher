function const = getConfig(varargin)
% getConfig  Returns a struct of constants for the project
isDebug = false;
if nargin >= 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'debug')
    isDebug = true;
end

if ~isDebug
    const.nEns = 51;
    const.leadtimeEns = 15; % days
    %%% preprocessing
    const.path.geo = fullfile('data', 'geo');
    const.path.outNhourRain = fullfile('res', 'nHourRain');
    const.path.d4pdf   = '/Volumes/koshiba/data/DAT/d4pdf/d4PDF_5kmDDS_JP';
    const.path.ens     = '/Volumes/koshiba/data/DAT/ensemble';
    const.path.kaiseki = '/Volumes/koshiba/data/DAT/kaiseki';
    %%% clustering 
    const.path.outClustered = fullfile('res', 'clustered');
else
    const.nEns = 4;
    const.leadtimeEns = 15; % days
    %%% preprocessing
    const.path.geo = fullfile('test', 'data', 'geo');
    const.path.outNhourRain = fullfile('test', 'res', 'nHourRain');
    % const.path.d4pdf        = fullfile('test', 'data', 'd4pdf', 'd4PDF_5kmDDS_JP');
    const.path.d4pdf        = '/Volumes/koshiba/data/DAT/d4pdf/d4PDF_5kmDDS_JP';
    % const.path.ens     = fullfile('test', 'data', 'ens');
    const.path.ens        = '/Volumes/koshiba/data/DAT/ensemble';
    const.path.kaiseki = fullfile('test', 'data', 'kaiseki', 'Data');
    %%% clustering 
    const.path.outClustered = fullfile('test', 'res', 'clustered');

    %%% matching
    const.path.outMatched = fullfile('test', 'res', 'matched');

    %%% postprocessing

    
    const.params.maxIter = 1000;
    const.params.threshold = 1e-3;
    
    % 追加の設定やバージョン情報などもここで管理
    const.version = 'v1.0';
end
        
end