function plotAll72hD4pdfOverlays(baseDir, cfg, const, varargin)
%PLOTALL72HD4PDFOVERLAYS Overlay all 72h rainfall events under baseDir.
%
% baseDir: e.g. ~/Dropbox/.../nHourRain/d4pdf/miya/72hours
% Each .dat is assumed to be [nCell x 72] (or [72 x nCell], will auto-fix).
%
% This function plots basin-mean (area-weighted) 72-h time series for all events.
%
% Options (Name,Value):
%   'UseAreaWeight' (true/false) default true
%   'MaxLines'      (inf or integer) default inf (subsample if too many)
%   'RandomSeed'    (integer) default 0
%   'PlotSummary'   (true/false) default true (mean + 10-90% band)
%   'YLim'          ([] or [ymin ymax]) default []
%   'LineWidth'     (double) default 0.6
%   'LineColor'     ([r g b]) default [0.2 0.2 0.2]
%   'Title'         (string/char) default ''

p = inputParser;
p.addParameter('UseAreaWeight', true, @(x)islogical(x) && isscalar(x));
p.addParameter('MaxLines', inf, @(x)isnumeric(x) && isscalar(x));
p.addParameter('RandomSeed', 0, @(x)isnumeric(x) && isscalar(x));
p.addParameter('PlotSummary', true, @(x)islogical(x) && isscalar(x));
p.addParameter('YLim', [], @(x)isnumeric(x) && (isempty(x) || numel(x)==2));
p.addParameter('LineWidth', 0.6, @(x)isnumeric(x) && isscalar(x));
p.addParameter('LineColor', [0.2 0.2 0.2], @(x)isnumeric(x) && numel(x)==3);
p.addParameter('Title', '', @(x)ischar(x) || isstring(x));
p.parse(varargin{:});
opt = p.Results;

% --- collect files recursively ---
L = dir(fullfile(baseDir, '**', '*.dat'));
assert(~isempty(L), 'No .dat found under: %s', baseDir);

% sort for reproducibility
[~,ord] = sort({L.name});
L = L(ord);

% --- get d4PDF point order and weights ---
[~, ~, idCell] = fetchD4pdfGridInfo(cfg, const);
nCell = numel(idCell);

w = ones(nCell,1) / nCell; % fallback
if opt.UseAreaWeight
    fnW = fullfile(const.path.geo, cfg.basin, 'area_per_d4pdfcell.csv');
    A = readmatrix(fnW, "NumHeaderLines", 1);
    % safety: ensure the first column matches idCell order
    assert(isequal(int32(A(:,1)), int32(idCell)), ...
        'area_per_d4pdfcell.csv order mismatch with fetchD4pdfGridInfo.');
    area = double(A(:,2));
    assert(all(isfinite(area)) && all(area>=0), 'Invalid area values in %s', fnW);
    w = area / sum(area);
end

% --- read all and compute basin-mean time series ---
nFile = numel(L);
Y = [];          % [nEvent x 72]
names = strings(nFile,1);

for i = 1:nFile
    fn = fullfile(L(i).folder, L(i).name);
    R = readmatrix(fn);

    if isvector(R)
        error('Unexpected vector in %s. Expect matrix nCell x 72.', fn);
    end

    % auto-fix orientation
    if size(R,1) == 72 && size(R,2) == nCell
        R = R.'; % -> nCell x 72
    end

    assert(size(R,1) == nCell, 'nCell mismatch in %s. got %d, expected %d', fn, size(R,1), nCell);

    nHour = size(R,2);
    if isempty(Y)
        Y = nan(nFile, nHour);
    else
        assert(size(Y,2) == nHour, 'nHour mismatch across files.');
    end

    Y(i,:) = (w' * R); % basin-mean [1 x 72]
    names(i) = string(L(i).name);
end

% --- subsample if too many lines ---
idx = 1:nFile;
if isfinite(opt.MaxLines) && nFile > opt.MaxLines
    rng(opt.RandomSeed);
    idx = sort(randsample(nFile, opt.MaxLines));
end
Yp = Y(idx,:);
namesP = names(idx);

% --- plot ---
x = 1:size(Y,2); % hour index 1..72

fig = figure;
fig.Color = 'w';
ax = axes(fig);
ax.Color  = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
ax.ZColor = 'k';
hold(ax,'on');

plot(ax, x, Yp', 'LineWidth', opt.LineWidth, 'Color', opt.LineColor);

% summary overlays
if opt.PlotSummary
    mu = mean(Y, 1, 'omitnan');
    q10 = quantile(Y, 0.10, 1);
    q90 = quantile(Y, 0.90, 1);

    % band (10-90%)
    fill(ax, [x, fliplr(x)], [q10, fliplr(q90)], [0.6 0.8 1.0], ...
         'EdgeColor','none', 'FaceAlpha', 0.25);

    % mean line
    plot(ax, x, mu, 'k-', 'LineWidth', 2.0);
end

grid(ax,'on');
xlabel(ax, 'Hour index within 72-h window');
ylabel(ax, 'Basin-mean rainfall [mm/h]');

if ~isempty(opt.YLim)
    ylim(ax, opt.YLim);
end

ttl = string(opt.Title);
if strlength(ttl) == 0
    ttl = sprintf('All 72-h events overlay (N=%d, plotted=%d)', nFile, numel(idx));
end
title(ax, ttl, 'Color','k');

% small note
text(ax, 0.01, 0.99, sprintf('baseDir: %s', baseDir), ...
     'Units','normalized', 'HorizontalAlignment','left', 'VerticalAlignment','top', ...
     'Color','k', 'Interpreter','none', 'FontSize', 9);

hold(ax,'off');

end