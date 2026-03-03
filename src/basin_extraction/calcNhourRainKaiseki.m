function calcNhourRainKaiseki(cfg, const)
% calcNhourRainKaiseki
%   気象庁解析雨量(1時間積算)から指定した流域の72h(一般にはnHourRain)雨量を抽出し,
%   d4PDFと同じ点列(d4PDF側の評価点)へ補間した nCellD4 x nHourRain の .dat を出力する.
%
% IMPORTANT:
%   解析雨量は「時刻ラベル=直前1時間積算の右端時刻」.
%   例: 10:00の解析雨量 = 9:00-10:00積算.
%   よって, 対象期間開始が tStartJST のとき, h=1..nHourRain で読むべきファイル時刻は
%     tEndJST = tStartJST + h hours
%   である.

% === constants for JMA analyzed rainfall grid ===
ROW = 3360;
COL = 2560;
WEST  = 118;
EAST  = 150;
NORTH = 48;
SOUTH = 20;
DX = 0.0125;
DY = 1/120;

nHourRain = cfg.nHourRain;

% --- single source of truth for the target window start (JST) ---
targetTimeStr = normalizeTargetTime(cfg.targetTime); % 'yyyyMMddHHmm' as string
tStartJST = datetime(targetTimeStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
assert(minute(tStartJST) == 0, 'targetTime minute must be 00.');

% output directory (align with ens design: .../<basin>/<72hours>/<targetTime>/)
targetKey = char(datestr(tStartJST, 'yyyymmddHHMM')); % 12 digits
outPath = fullfile(const.path.outNhourRain, 'kaiseki', cfg.basin, ...
                   sprintf('%dhours', nHourRain), targetKey);

% --- d4PDF target points (basin points) ---
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCellD4 = numel(idD4pdfcell);

% --- build axis vectors in ascending order (required by griddedInterpolant) ---
lonVec = WEST + DX/2 : DX : EAST - DX/2;     % length = COL, ascending
latVec = SOUTH + DY/2 : DY : NORTH - DY/2;   % length = ROW, ascending (south->north)

assert(numel(lonVec) == COL, 'lonVec length mismatch.');
assert(numel(latVec) == ROW, 'latVec length mismatch.');

% interpolant (Values will be updated each hour)
F = griddedInterpolant({latVec, lonVec}, zeros(ROW, COL), 'linear', 'none');
% NOTE: If you ever find a few points slightly outside the grid, switch to 'nearest':
% F = griddedInterpolant({latVec, lonVec}, zeros(ROW, COL), 'linear', 'nearest');

% preallocation: nCellD4 x nHourRain
resampledRain = zeros(nCellD4, nHourRain);

% convert JST end-time labels to UTC file time
for h = 1:nHourRain
    % end time label of 1-hour accumulation
    tEndJST = tStartJST + hours(h);
    tEndUTC = tEndJST - hours(9);

    Y = year(tEndUTC); M = month(tEndUTC); D = day(tEndUTC); H = hour(tEndUTC);

    % build filename (UTC)
    tmp = sprintf('Z__C_RJTD_%d%02d%02d%02d0000_SRF_GPV_Ggis1km_Prr60lv_ANAL_0_int.bin', ...
                  Y, M, D, H);
    fn = fullfile(const.path.kaiseki, sprintf('%d', Y), sprintf('%02d', M), sprintf('%02d', D), tmp);
    assert(exist(fn,'file')==2, 'File not found: %s', fn);

    % read + convert (level -> mm/h) inside readKaiseki, or already mm/h
    rain = readKaiseki(fn, ROW, COL);
    % fprintf("raw stats: min=%.1f max=%.1f\n", min(rain(:)), max(rain(:))); 
    
    % reshape to 2D grid [ROW x COL]
    % JMA binary is stored row-wise from upper-left. Your reshape([COL,ROW])' is consistent.
    rainGrid = reshape(rain, [COL, ROW])';  % [ROW x COL], row direction is NORTH->SOUTH (descending lat)

    % eliminate NaN/Inf to avoid propagation in interpolation
    % (for matching purpose, treat missing as 0 mm/h)
    rainGrid(~isfinite(rainGrid)) = 0;

    % latVec is SOUTH->NORTH (ascending). rainGrid is NORTH->SOUTH, so flip vertically.
    V = flipud(rainGrid); % now V rows correspond to SOUTH->NORTH, consistent with latVec

    % resampling to d4PDF points (query order: lat, lon)
    F.Values = V;
    resampled = F(latD4pdf, lonD4pdf);

    % sanity checks (after missing-handling, NaN should not remain unless out-of-range)
    if any(~isfinite(resampled))
        error(['NaN/Inf found after resampling at h=%d (tEndJST=%s). ' ...
               'Check grid coverage or switch extrapolation to nearest.'], ...
              h, char(datetime(tEndJST,'Format','yyyy-MM-dd HH:mm')));
    end

    resampledRain(:, h) = resampled;

    fprintf('Read analyzed rainfall labeled at JST %s (UTC %s)\n', ...
            char(datetime(tEndJST,'Format','yyyy-MM-dd HH:mm')), ...
            char(datetime(tEndUTC,'Format','yyyy-MM-dd HH:mm')));
end

% output: nCellD4 x nHourRain
outFn = sprintf('%s.dat', targetKey);
writeMatrixToDir(resampledRain, outPath, outFn);
end