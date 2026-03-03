function calcNhourRainEns(cfg, const)
% calcNhourRainEns
%   JWAアンサンブル降雨予測csvから指定した流域のnHourRain時間雨量(時空間分布)を抽出し,
%   d4PDFと同じ点列(d4PDF側の評価点)へ補間した nCellD4 x nHourRain の .dat を出力する.

% --- target time (single source of truth) ---
targetTimeStr = normalizeTargetTime(cfg.targetTime); % 'yyyyMMddHHmm'
tTargetJST = datetime(targetTimeStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');

% enforce 00 minutes (your data assumes 09:00 or 21:00)
assert(minute(tTargetJST) == 0, 'targetTime minute must be 00.');
nHourRain = cfg.nHourRain;

% 12-hour stepping assumption
assert(mod(nHourRain,12) == 0, 'nHourRain must be multiple of 12.');

% output folder uses the fixed target time
targetTime = char(datestr(tTargetJST, 'yyyymmddHHMM')); % e.g., 201709302100
outPath = fullfile(const.path.outNhourRain, ...
                   'ens', cfg.basin, sprintf('%dhours', nHourRain), targetTime);

% --- 0) grid preparation (ens grid + d4pdf points) ---
% use member 01 at targetTime just to read grid info
fnGrid = findEnsCsv(const.path.ens, cfg.basin, year(tTargetJST), targetTime, 1);
assert(exist(fnGrid,'file')==2, "Cannot find %s", fnGrid);

[ensLon, ensLat, nRow, nCol] = fetchBasinGridEns(fnGrid);

% header sanity check (optional)
tmp = readmatrix(fnGrid, 'NumHeaderLines', 0, 'Delimiter', ',');
nRowH = tmp(1, 13);
nColH = tmp(1, 12);
if ~(nRowH == nRow && nColH == nCol)
    error('Grid size mismatch. header=(%d,%d) vs fetchBasinGridEns=(%d,%d)', nRowH, nColH, nRow, nCol);
end
nCellEns = nRow * nCol;

% --- 1) d4PDF target points (basin points, ordered consistently) ---
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCellD4 = numel(idD4pdfcell);

% --- 2) build 1D grid vectors and make them ascending ---
lonVec = ensLon(1, :);     % 1 x nCol
latVec = ensLat(:, 1);     % nRow x 1

flipLon = false;
flipLat = false;

if lonVec(1) > lonVec(end)
    lonVec = fliplr(lonVec);
    flipLon = true;
end
if latVec(1) > latVec(end)
    latVec = flipud(latVec);
    flipLat = true;
end

assert(issorted(lonVec), 'lonVec is not sorted ascending after flip.');
assert(issorted(latVec), 'latVec is not sorted ascending after flip.');

F = griddedInterpolant({latVec, lonVec}, zeros(nRow, nCol), 'linear', 'none');

% optional: upper bound sanity check
if isfield(cfg,'maxRain')
    maxRain = cfg.maxRain;
else
    maxRain = 2000; % mm/h, set conservative
end

% --- 3) loop over initial times and members ---
nInit = 31 - nHourRain/12; % 360h horizon with 12h stepping
assert(nInit >= 1, 'nInit became < 1. Check nHourRain.');

for initTimeIdx = 1:nInit

    % init time shifts earlier by 12h each step
    tInitJST = tTargetJST - hours(12*(initTimeIdx-1));
    initTime = char(datestr(tInitJST, 'yyyymmddHHMM')); % e.g., 201709302100

    for iMember = cfg.memEnsStart:cfg.memEnsEnd

        fn = findEnsCsv(const.path.ens, cfg.basin, year(tInitJST), initTime, iMember);
        rain = readmatrix(fn, 'NumHeaderLines', 0, 'Delimiter', ',');

        % remove 1 header row per hour: (1 header + nRow rain rows)
        isRain = mod((1:size(rain,1))', nRow+1) ~= 1;
        rain = rain(isRain, 1:nCol); % [(nRow*numHours) x nCol]

        % reshape to [numHours x nCellEns]
        numHours = size(rain,1) / nRow;
        assert(mod(size(rain,1), nRow) == 0, 'Row count is not divisible by nRow in %s', fn);

        rain = reshape(rain, nRow, numHours, nCol);  % [nRow x numHours x nCol]
        rain = permute(rain, [1, 3, 2]);             % [nRow x nCol x numHours]
        rain = reshape(rain, [nCellEns, numHours])'; % [numHours x nCellEns]

        % extract target nHourRain window at this initTimeIdx (12h stepping)
        t1 = 12*(initTimeIdx-1) + 1;
        t2 = t1 + nHourRain - 1;
        assert(t2 <= numHours, 'Requested window exceeds available hours in %s', fn);

        rain72 = rain(t1:t2, :)'; % [nCellEns x nHourRain]

        % resample to d4PDF points -> [nCellD4 x nHourRain]
        rainD4 = zeros(nCellD4, nHourRain);

        for tt = 1:nHourRain
            V = reshape(rain72(:,tt), [nRow, nCol]); % [nRow x nCol], row=lat, col=lon

            if flipLon; V = fliplr(V); end
            if flipLat; V = flipud(V); end

            F.Values = V;
            rainD4(:,tt) = F(latD4pdf, lonD4pdf); % NOTE: (lat, lon) order
        end

        % sanity checks
        if any(~isfinite(rainD4(:)))
            error(['NaN/Inf produced by resampling in %s. ' ...
                   'Check that d4PDF points are inside ensemble grid and that input has no missing.'], fn);
        end
        if any(rainD4(:) < 0)
            error('Negative rainfall after resampling in %s', fn);
        end
        if max(rainD4(:)) > maxRain
            error('Unrealistic rainfall (>%.1f) in %s. Check units/interp.', maxRain, fn);
        end

        % output: nCellD4 x nHourRain
        outFn = sprintf('%s_%03d.dat', initTime, iMember);
        writeMatrixToDir(rainD4, outPath, outFn);
    end

    fprintf('%s has been output successfully at %s\n', initTime, datetime('now','Format','MM/dd HH:mm:ss'));
end

end

function fn = findEnsCsv(baseEnsDir, basin, yearNum, initTimeStr, memberIdx)
% tries <base>/<basin>/<year>/<init>_<mem>.csv, then <base>/<basin>/<init>_<mem>.csv
fnA = fullfile(baseEnsDir, basin, num2str(yearNum), sprintf('%s_%02d.csv', initTimeStr, memberIdx));
fnB = fullfile(baseEnsDir, basin, sprintf('%s_%02d.csv', initTimeStr, memberIdx));
if exist(fnA,'file')==2
    fn = fnA;
elseif exist(fnB,'file')==2
    fn = fnB;
else
    error('Cannot find ensemble csv: %s (or %s)', fnA, fnB);
end
end