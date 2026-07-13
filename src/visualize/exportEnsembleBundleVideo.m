function exportEnsembleBundleVideo(cfg, const, basin, targetTimeStr, initTimeList, memberList, fnAnaDat, outMp4, yLim, fps)
% Export MP4: each frame shows ensemble bundle + analyzed rainfall.
%
% yLim: optional fixed y-limits, e.g. [0 80]. If empty, auto-fixed across all frames.
% fps : frames per second (default 3)

if nargin < 10 || isempty(fps); fps = 3; end
if nargin < 9; yLim = []; end

tTarget = datetime(normalizeTargetTime(targetTimeStr), 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
nHour = cfg.nHourRain;
tAxis = tTarget + hours(1:nHour);

w = getBasinAreaWeights(cfg, const);

Ana = readmatrix(fnAnaDat);
anaMean = (w' * Ana); % 1 x 72

% auto yLim across all frames if not provided
if isempty(yLim)
    yMax = max(anaMean);
    for k = 1:numel(initTimeList)
        initStr = initTimeList{k};
        for j = 1:numel(memberList)
            mem = memberList(j);
            fnEns = fullfile(const.path.outNhourRain, 'ens', basin, sprintf('%dhours', nHour), ...
                char(string(tTarget,'yyyyMMddHHmm')), sprintf('%s_%03d.dat', initStr, mem));
            R = readmatrix(fnEns);
            yMax = max(yMax, max(w'*R));
        end
    end
    yLim = [0, yMax];
end

vw = VideoWriter(outMp4, 'MPEG-4');
vw.FrameRate = fps;
vw.Quality   = 95;   % 0-100, higher = better (and larger)
open(vw);

fig = figure('Visible','off', 'Color','w', 'Units','pixels', 'Position',[60 60 960 240]);
ax = axes(fig);

for k = numel(initTimeList):-1:1
    initStr = initTimeList{k};
    tInit = datetime(initStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
    leadHours = round(hours(tTarget - tInit));

    M = numel(memberList);
    ensMean = nan(M, nHour);

    for j = 1:M
        mem = memberList(j);
        fnEns = fullfile(const.path.outNhourRain, 'ens', basin, sprintf('%dhours', nHour), ...
            string(tTarget,'yyyyMMddHHmm'), sprintf('%s_%03d.dat', initStr, mem));
        R = readmatrix(fnEns);
        ensMean(j,:) = (w' * R); % 1 x 72
    end

    cla(ax);
    plot(ax, tAxis, ensMean', 'LineWidth', 0.8);
    hold(ax,'on');
    plot(ax, tAxis, anaMean, 'k-', 'LineWidth', 2.5); % analyzed thicker
    hold(ax,'off');

    grid(ax,'on');
    ylim(ax, yLim);
    xlabel(ax, 'Time (JST)');
    ylabel(ax, 'Rain [mm/h]');
    % txt = sprintf('Target start: %s JST, Init: %s JST, Lead: %d h, %d members', ...
    %     char(tTarget,'yyyy-MM-dd HH:mm'), initStr, leadHours, M);
    txt = sprintf('Target start: %s, Lead: %d h, %d members', ...
        char(tTarget,'yyyy-MM-dd HH:mm'), leadHours, M);
    title(ax, txt, 'Color','k');
    ax.Color  = 'w';
    ax.XColor = 'k';
    ax.YColor = 'k';
    ax.ZColor = 'k';

    drawnow;
    writeVideo(vw, getframe(fig));
end

close(vw);
close(fig);

fprintf("Saved MP4: %s\n", outMp4);
end