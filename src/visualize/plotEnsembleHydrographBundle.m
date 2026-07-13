function plotEnsembleHydrographBundle(cfg, const, basin, targetTimeStr, initTimeList, memberList, fnAnaDat, yLim)
% Plot basin-mean 72h time series for all members, for multiple init times.
%
% yLim: optional fixed y-limits, e.g. [0 80]. If empty, uses [0, max across all shown].

if nargin < 8
    yLim = [];
end

% --- target time (JST) ---
tTarget = datetime(normalizeTargetTime(targetTimeStr), 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
nHour = cfg.nHourRain;
tAxis = tTarget + hours(1:nHour); % label as end time

% --- analyzed rainfall ---
w = getBasinAreaWeights(cfg, const);

Ana = readmatrix(fnAnaDat);
anaMean = (w' * Ana);

% --- precompute yLim if not given (across all tiles and members) ---
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

% --- figure/axes style (white background) ---
fig = figure;
fig.Color = 'w';
tl = tiledlayout(numel(initTimeList), 1, 'Padding','compact', 'TileSpacing','compact');

for k = 1:numel(initTimeList)
    initStr = initTimeList{k};
    tInit = datetime(initStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
    leadHours = hours(tTarget - tInit); % duration in hours
    leadHours = round(leadHours);       % should be 0,12,24,...

    nexttile;

    % read all members
    M = numel(memberList);
    ensMean = nan(M, nHour);
    for j = 1:M
        mem = memberList(j);
        fnEns = fullfile(const.path.outNhourRain, 'ens', basin, sprintf('%dhours', nHour), ...
            string(tTarget,'yyyyMMddHHmm'), sprintf('%s_%03d.dat', initStr, mem));
        R = readmatrix(fnEns); % [nCell x 72]
        ensMean(j,:) = (w' * R);
    end

    plot(tAxis, ensMean', 'LineWidth', 0.8);
    hold on;
    plot(tAxis, anaMean, 'k-', 'LineWidth', 2.5); % analyzed thicker
    hold off;

    grid off;
    ylim(yLim);
    ylabel('rain [mm/h]'); % basin mean rain
    ax = gca;
    ax.Color  = 'w';
    ax.XColor = 'k';
    ax.YColor = 'k';
    ax.ZColor = 'k';

    title(sprintf('Init = %s (JST), Lead = %d h, %d members', initStr, leadHours, M), 'Color','k');

    if k == numel(initTimeList)
        xlabel('Time (JST)');
    else
        set(gca,'XTickLabel',[]);
    end
end

% txt = sprintf('Ensamble 72-h basin-mean rainfall bundles (Target start: %s JST)',...
%     char(tTarget,'yyyy-MM-dd HH:mm'));
txt = sprintf('Ens 72-h rain Target start: %s', char(tTarget,'yyyy-MM-dd HH:mm'));

title(tl, txt, 'Color','k');
end