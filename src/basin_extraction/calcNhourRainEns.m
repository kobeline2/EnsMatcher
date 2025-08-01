function calcNhourRainEns(cfg, const)
% calcNhourRainEns Brief description of the function.
%
%   calcNhourRainD4PDF(pathConfig, varargin)
%
% Description:
%   アンサンブル予測のcsvファイルから指定した流域のh時間雨量を抽出
%   用意する雨データ: yyyyMMddHHmm_mem.csv (アンサンブル降雨予測)
%   入手先: 一般財団法人 日本気象協会
%
% Input Arguments:
%   cfg  - rain_extraction.yaml
%
% Examples:
%   pathConfig = 'config/rain_extraction.yaml';
%   const = getConfig('debug');
%   cfg = readyaml(pathConfig);
%   calcNhourRainEns(cfg, const);
%
% Author: T.Koshiba, S.Ono
% Date: 2025-03-28
% Revision: 1.0
%
% Copyright (c) 2025, DPRI, Kyoto Univ.
% All rights reserved.
%

Y = cfg.Y; M = cfg.M; D = cfg.D; H = cfg.H;  
nHourRain = cfg.nHourRain;
outPath = fullfile(const.path.outNhourRain, ...
                   'ens', ...
                   cfg.basin, ...
                   sprintf('%dhours', nHourRain), ...
                   sprintf('%04d%02d%02d%02d00', Y, M, D, H));

% アンサンブル予測のグリッド情報取得
fn = fullfile(const.path.ens, cfg.basin, num2str(Y),...
              sprintf('%04d%02d%02d%02d00_01.csv', Y, M, D, H));
rain = readmatrix(fn, 'NumHeaderLines', 0, 'Delimiter', ',');
nRow = rain(1, 13); % アンサンブル予測のグリッドの行数
nCol = rain(1, 12); % アンサンブル予測のグリッドの列数
nCell = nRow * nCol;

% 初期時刻毎，メンバー毎にh時間の流域平均雨量を算出してdatファイルに出力
for initTimeIdx = 1:31-nHourRain/12 % 初期時刻(31 = 1+(15日/0.5日))
    % 初期時刻の文字列の作成
    initTime = sprintf('%04d%02d%02d%02d00', Y, M, D, H);
    
    for iMember = cfg.memEnsStart:cfg.memEnsEnd
        % 雨量の読み込み
        fn = fullfile(const.path.ens, cfg.basin, num2str(Y), ...
                      sprintf('%s_%02d.csv', initTime, iMember));
        rain = readmatrix(fn, 'NumHeaderLines', 0, 'Delimiter',',');
        isRain = mod(1:length(rain), nRow+1) ~= 1; % 雨量が格納されている行番号を取得
        rain = rain(isRain, 1:nCol); % 雨量のみの行列を作成
        
        % rainデータは(nRow*nHour)*nColという二次元データ. 
        % これを(nRow*nCol)*nHourに変換し, 必要な時間データを抽出する(最終行). 
        numHours = length(rain)/nRow;
        rain = reshape(rain, nRow, numHours, nCol);
        rain = permute(rain, [1, 3, 2]);
        rain = reshape(rain, [nCell, numHours])';
        rain = rain(12*(initTimeIdx-1)+1:12*(initTimeIdx-1)+nHourRain, :)';
    
        % 流域のh時間雨量をdatファイルに出力
        outFn = sprintf('%s_%03d.dat', initTime, iMember);
        writeMatrixToDir(rain, outPath, outFn);
    end
    % logging
    fprintf('%s has been output successfully at %s\n', ...
            initTime, datetime('now','Format','MM/dd HH:mm:ss'))

    % 初期時刻の更新(-12h)
    [Y, M, D, H] = updateDatetime(datetime(Y, M, D, H, 00, 00), -hours(12));

end
end