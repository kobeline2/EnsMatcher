function calcNhourRainD4PDF(cfg, const)
% calcNhourRainD4PDF Brief description of the function.
%
%   calcNhourRainD4PDF(pathConfig, varargin)
%
% Description:
%   1.d4PDF_5kmDDS_JPのrain.ncファイルから1年間の1時間降水量を抽
%   2.指定した流域の年最大(2,3,...位)n時間雨量およびその初期時刻を抽出
%   % 用意する雨データ: rain.nc
%     入手先: https://search.diasjp.net/ja/dataset/d4PDF_5kmDDS_JP
%
% Input Arguments:
%   cfg  - rain_extraction.yaml
%
% Examples:
%   pathConfig = 'config/rain_extraction.yaml';
%   calcNhourRainD4PDF(pathConfig, 'debug');
%
% Author: T.Koshiba, S.Ono
% Date: 2025-03-280
% Revision: 1.0
%
% Copyright (c) 2025, DPRI, Kyoto Univ.
% All rights reserved.
%

nHourRain = cfg.nHourRain;
outPath = fullfile(const.path.outNhourRain, ...
                   'd4pdf', ...
                   cfg.basin, ...
                   sprintf('%dhours', nHourRain));

% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
% d4PDF計算点の支配領域面積のデータがあるフォルダ
fn = fullfile(const.path.geo, cfg.basin, 'area_per_d4pdfcell.csv');
area_per_d4pdfcell = readmatrix(fn, "NumHeaderLines", 1);
cellId = int32(area_per_d4pdfcell(:, 1)); % 通し番号
cellArea = area_per_d4pdfcell(:, 2); % ティーセン分割によって作られた各領域が流域と重なる面積

% 雨量の読み込み => 1時間雨量の抽出 => 最大雨量の出力
parfor iMember = cfg.memStart:cfg.memEnd
    memberDir = sprintf('HPB_m%03d', iMember);
    
    % 年ごとに年最大雨量を抽出してdatファイルに出力
    for iYear = cfg.yearStart:cfg.yearEnd % year
        % rain.ncの読み込み
        % 助走期間を考慮して9/1~8/31を1セットとする
        rain = fetchBasinD4pdfRain(const, cfg, memberDir, iYear, cellId);
        basinMeanRain = rain' * cellArea / sum(cellArea); % 加重平均
    
        % 年月日時のベクトルを作成
        dailyTimes = datetime(iYear, 09, 01, 00, 00, 00,...
                              'Format', 'yyyy-MMdd-HH') ...
                     + hours(0:length(basinMeanRain)-1);
        
        [~, idx, sums] = extractTopNonOverlappingSegments(basinMeanRain, nHourRain, cfg.rank);
        for I = 1:cfg.rank
            % n時間の雨を1時間ごとに出力(n時間雨量の最大値をファイル名に入れる)
            outDir = fullfile(outPath, num2str(I));
            outFn  = sprintf('m%03d_%s_%.0fmm.dat', ...
                             iMember ,dailyTimes(idx(I)), sums(I));
            writeMatrixToDir(rain(:, idx(I):idx(I)+nHourRain-1), ...
                             outDir, outFn)
        end

        % logging
        fprintf('m%03d %d has run successfully at %s\n', ...
                iMember, iYear, datetime('now','Format','MM/dd HH:mm:ss'))
    end
end
end