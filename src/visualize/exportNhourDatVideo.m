function exportNhourDatVideo(fnDat, cfg, const, outDir, clim, fps, step)
%EXPORTNHOURDATVIDEO Export hourly maps as MP4 video.
%
% fnDat : path to .dat (matrix [nCellD4 x nHour])
% outDir: output directory
% clim  : [cmin cmax]. If empty, uses [0 max(R(:))].
% fps   : frames per second (default 6)
% step  : frame step in hours (default 1) 1=every hour

if nargin < 4 || isempty(outDir)
    outDir = fullfile(pwd, "fig_out");
end
if ~exist(outDir, 'dir'); mkdir(outDir); end

if nargin < 6 || isempty(fps);  fps = 6; end
if nargin < 7 || isempty(step); step = 1; end

% time label (optional)
targetTimeStr = normalizeTargetTime(cfg.targetTime);
tStartJST = datetime(targetTimeStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
assert(minute(tStartJST) == 0, 'targetTime minute must be 00.');

% d4PDF basin points
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCellD4 = numel(idD4pdfcell);

% read data
R = readmatrix(fnDat);
assert(~isvector(R), 'Expected matrix [nCellD4 x nHour], got vector.');
assert(size(R,1) == nCellD4, 'Row size mismatch. file=%d, d4pdf=%d', size(R,1), nCellD4);
nHour = size(R,2);

% clim
if nargin < 5 || isempty(clim)
    clim = [0, max(R(:))];
end
assert(numel(clim)==2 && clim(1) <= clim(2), 'clim must be [cmin cmax].');

% output file
[~, base, ~] = fileparts(fnDat);
mp4Path = fullfile(outDir, base + "_hourly.mp4");

% video writer
vw = VideoWriter(mp4Path, 'MPEG-4');
vw.FrameRate = fps;
open(vw);

% figure (off-screen)
fig = figure('Visible','off');
ax = axes(fig);

hSc = scatter(ax, lonD4pdf, latD4pdf, 10, R(:,1), 'filled');
axis(ax, 'equal');
axis(ax, 'tight');
set(ax, 'YDir', 'normal');
grid(ax, 'on');
xlabel(ax, 'Longitude [deg]');
ylabel(ax, 'Latitude [deg]');
caxis(ax, clim);
cb = colorbar(ax);
ylabel(cb, 'Rainfall [mm/h]');
fig.Color = 'w';
ax.Color  = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
ax.ZColor = 'k';
cb.Color = 'k';

% render frames
for tt = 1:step:nHour
    hSc.CData = R(:,tt);

    tLabel = tStartJST + hours(tt); % 表示用. 解析雨量の右端時刻ラベルに合わせたいなら +hours(tt)のままでOK
    title(ax, sprintf('%s, h=%d/%d, JST %s, clim=[%g,%g]', ...
        base, tt, nHour, char(tLabel,'yyyy-MM-dd HH:mm'), clim(1), clim(2)));

    drawnow;
    frame = getframe(fig);
    writeVideo(vw, frame);
end

close(vw);
close(fig);

fprintf("Saved MP4: %s\n", mp4Path);
end