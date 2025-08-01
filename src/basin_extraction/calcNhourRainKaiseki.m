function calcNhourRainKaiseki(cfg, const)
% calcNhourRainEns Brief description of the function.
%
%   calcNhourRainD4PDF(pathConfig, varargin)
%
% Description:
%   気象庁解析雨量から指定した流域の雨を抽出する → resampling
% 
% Input Arguments:
%   cfg  - rain_extraction.yaml
%
% Examples:
%   pathConfig = 'config/rain_extraction.yaml';
%   const = getConfig('debug');
%   cfg = readyaml(pathConfig);
%   calcNhourRainKaiseki(cfg, const);
%
% Author: T.Koshiba, S.Ono
% Date: 2025-03-28
% Revision: 1.0
%
% Copyright (c) 2025, DPRI, Kyoto Univ.
% All rights reserved.
%
% 解析雨量データに関する定数
ROW = 3360;  % 行数
COL = 2560;  % 列数
WEST = 118;  % 領域の最西端の経度
EAST = 150;  % 領域の最東端の経度
NORTH = 48;  % 領域の最北端の緯度
SOUTH = 20;  % 領域の最南端の緯度
DX = 0.0125; % x(経度)方向の格子点の間隔
DY = 1/120;  % y(緯度)方向の格子点の間隔

nHourRain = cfg.nHourRain; % 雨の期間
outPath = fullfile(const.path.outNhourRain, 'kaiseki', cfg.basin,...
                   sprintf('%shours', num2str(nHourRain)));


% 解析雨量, d4PDFの格子点の緯度経度を取得(resamplingの準備)
[lon, lat] = meshgrid(WEST +DX/2 : DX : EAST -DX/2, ...
                      NORTH-DY/2 :-DY : SOUTH+DY/2);
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);

% 解析雨量の読み込み → レベル値から雨量(mm/h)に変換 → resampling

% 協定世界時(UTC)に設定
tmpDate = datetime(num2str(cfg.targetTime), 'InputFormat', 'yyyyMMddHHmm');
tmpDate = tmpDate - hours(9); % UTC
Y = tmpDate.Year;
M = tmpDate.Month;
D = tmpDate.Day;
H = tmpDate.Hour;

resampledRain = zeros(length(idD4pdfcell), nHourRain); % preallocation

for iTime = 1:nHourRain
    % 時刻の更新(+1h)
    [Y, M, D, H] = updateDatetime(datetime(Y, M, D, H, 00, 00), hours(1));

    % 解析雨量の読み込み
    tmp = sprintf('Z__C_RJTD_%d%02d%02d%02d0000_SRF_GPV_Ggis1km_Prr60lv_ANAL_0_int.bin', ...
             Y, M, D, H);
    fn = fullfile(const.path.kaiseki, ...
                  sprintf('%d', Y), ...
                  sprintf('%02d', M), ...
                  sprintf('%02d', D), tmp);
    rain = readKaiseki(fn);
    
    % resampling
    % 解析雨量は左上から右下へ"横方向"に並んでいるため，
    % [col,row]でreshapeしてから転置する
    rain = reshape(rain, [COL, ROW])';
    % resampling
    resampledRain(:, iTime) = interp2(lon, lat, rain, lonD4pdf, latD4pdf);
    fprintf('Generated datetime: %s\n',...
            char(datetime(Y, M, D, H, 00, 00, 'Format', 'yyyy-MM-dd HH:mm:ss')));
end

% resampledRainをdatファイルに出力
outFn = sprintf('%s.dat', num2str(cfg.targetTime));
writeMatrixToDir(resampledRain, outPath, outFn)

end


