function runRainExtraction(pathConfig, varargin)
% configファイルのdatatypeに基づいて, 
% {d4pdf, ens, kaiseki}データに対してnHourRainの抽出を行う.
%

if nargin >= 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'debug')
    configArg = {'debug'};
end

const = getConfig(configArg{:});
cfg = readyaml(pathConfig);
    
    % Choose the process based on processType.
    switch cfg.datatype
        case 'd4pdf'
            calcNhourRainD4PDF(cfg, const);
        case 'ens'
            calcNhourRainEns(cfg, const);
        case 'kaiseki'
            calcNhourRainKaiseki(cfg, const);
        otherwise
            error('Unknown process type: %s', cfg.datatype);
    end
end
