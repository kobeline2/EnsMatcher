pathConfig = 'config/clustering.yaml';
const = getConfig('debug');
cfg = readyaml(pathConfig);
[idx, centers, bestK, rain] = clusteringSpatioTemp(cfg, const);

%%
plotClusteredLines(idx, rain, cfg)

%%
function plotClusteredLines(idx, rain, cfg)
nCell = size(rain, 2)/cfg.nHourRain;
K      = numel(unique(idx));   % クラスタ数
cmap   = lines(K);             % 好みで: parula, turbo, hsv など

figure;
hold on;

for k = 1:K
    r = rain(idx==k, :);
    r = reshape(r', nCell, cfg.nHourRain, []);
    r = squeeze(mean(r, 1));
    plot(r , ...
        'Color'       , cmap(k,:) , ...
        'LineWidth'   , 0.8       , ...
        'HandleVisibility','off'); % 凡例を汚さない
end

% 代表曲線だけ凡例に出したい場合
for k = 1:K
    r = rain(idx==k, :);
    r = reshape(r', nCell, cfg.nHourRain, []);
    r = squeeze(mean(r, 1));
    h(k) = plot(mean(r, 2), ...
        'Color','k', ...
        'LineWidth',1.5);
end
legend(h,arrayfun(@(x)sprintf('Cluster %d',x),1:K,'Uni',0));

xlabel('Hours');
ylabel('Average Rainfall [mm]');
end