function exportNhourDatMap(fnDat, cfg, const, outDir, clim)
%EXPORTNHOURDATMAP Save map snapshots as files with fixed color limits.
%
% fnDat : path to nCellD4 x nHourRain .dat (e.g., 201709302100.dat)
% outDir: output folder
% clim  : [cmin cmax]. If empty or not given, uses [0 max(R(:))].
%
% Outputs:
%  - <outDir>/<basename>_snapshots.png
%  - <outDir>/<basename>_snapshots.pdf
%  - <outDir>/<basename>_basin_mean.png

if nargin < 4 || isempty(outDir)
    outDir = fullfile(pwd, "fig_out");
end
if ~exist(outDir, 'dir'); mkdir(outDir); end

% --- time axis ---
targetTimeStr = normalizeTargetTime(cfg.targetTime);
tStartJST = datetime(targetTimeStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
assert(minute(tStartJST) == 0, 'targetTime minute must be 00.');

% --- d4PDF basin points ---
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCellD4 = numel(idD4pdfcell);

% --- read matrix ---
R = readmatrix(fnDat);
assert(~isvector(R), 'Expected matrix [nCellD4 x nHourRain], got vector.');
assert(size(R,1) == nCellD4, 'Row size mismatch. file=%d, d4pdf=%d', size(R,1), nCellD4);
nHour = size(R,2);

% --- fixed clim across all snapshots ---
if nargin < 5 || isempty(clim)
    cmin = 0;
    cmax = max(R(:));
    clim = [cmin, cmax];
end
assert(numel(clim)==2 && clim(1) <= clim(2), 'clim must be [cmin cmax].');

% --- choose snapshot hours ---
snapHours = unique(round([1, 12, 24, 36, 48, 60, nHour]));
snapHours = snapHours(snapHours>=1 & snapHours<=nHour);
nSnap = numel(snapHours);

% --- basename ---
[~, base, ~] = fileparts(fnDat);

% --- 1) basin-mean time series (unweighted) ---
tEnd = tStartJST + hours(1:nHour); % label as end time (consistent with your code)
fig1 = figure('Visible','off');
plot(tEnd, mean(R,1));
grid on;
xlabel('Time (JST)');
ylabel('Mean rainfall over points [mm/h]');
title(sprintf('Analyzed rainfall (unweighted mean), start=%s', char(tStartJST,'yyyy-MM-dd HH:mm')));
exportgraphics(fig1, fullfile(outDir, base + "_basin_mean.png"), 'Resolution', 200);
close(fig1);

% --- 2) tiled snapshot maps (single figure) ---
% decide tile layout
nCol = 4;
nRow = ceil(nSnap / nCol);

fig2 = figure('Visible','off');
tiledlayout(nRow, nCol, 'Padding','compact', 'TileSpacing','compact');

for ii = 1:nSnap
    h = snapHours(ii);
    nexttile;

    scatter(lonD4pdf, latD4pdf, 10, R(:,h), 'filled');
    axis equal tight;
    set(gca, 'YDir', 'normal');
    grid on;
    caxis(clim);

    tt = tEnd(h);
    title(sprintf('h=%d, %s', h, char(tt,'MM/dd HH:mm')), 'FontSize', 9);
    xlabel('Lon'); ylabel('Lat');
end

% single colorbar for the whole layout
cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Rainfall [mm/h]');

sgtitle(sprintf('Snapshots with fixed color limits: [%g, %g] mm/h', clim(1), clim(2)));

exportgraphics(fig2, fullfile(outDir, base + "_snapshots.png"), 'Resolution', 250);
exportgraphics(fig2, fullfile(outDir, base + "_snapshots.pdf"), 'ContentType', 'vector');
close(fig2);

fprintf("Saved figures to: %s\n", outDir);
end