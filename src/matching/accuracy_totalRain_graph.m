%%% 流域平均総雨量と平均的中率の散布図を描画 %%%

% パラメータの設定
basinList = ["yodo","agano","mogami","tenryu","chikugo","yahagi","miya"];
matchingMethodList = ["euclid","cos"];
nCluster = 6;
nTargetEvent = 4; % 対象イベント数
figurePosition = [500 200 800 400]; % 3列目が幅，4列目が高さ
color = lines; % plotの色
mkr = ["o","diamond"]; % scatterのマーカー記号
% 総雨量データがあるフォルダ
totalRainFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','targetEvent');
% 的中率データがあるフォルダ
accuracyFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','Result');

% データの読み込み + plot
p = gobjects(length(basinList),length(matchingMethodList)*nTargetEvent);
legendName = string(zeros(1,length(matchingMethodList)*length(basinList)));
figure('Position',figurePosition)
hold on
for iBasin = 1:length(basinList)
    for i = 1:length(matchingMethodList)
        % 総雨量データの読み込み
        totalRainFile = fullfile(totalRainFolder, ...
                                 sprintf('%s_targetEvent.dat',basinList(iBasin)));
        totalRainFileData = readmatrix(totalRainFile);
        totalRain = totalRainFileData(:,2);
        % 的中率データの読み込み
        accuracyFile = fullfile(accuracyFolder,basinList(iBasin),'72hours','matching','both', ...
                           sprintf('%dclusters_nash',nCluster), ...
                           sprintf('hitRatio_%s.dat',matchingMethodList(i)));
        accuracyFileData = readmatrix(accuracyFile);
        targetEvent = num2str(accuracyFileData(:,1));
        meanAccuracy = accuracyFileData(:,2);
        % plot
        for j = 1:nTargetEvent
            p(iBasin,length(matchingMethodList)*(j-1)+i) ...
            = scatter(totalRain(j),meanAccuracy(j), ...
                      48,mkr(i),'filled', ...
                      'MarkerFaceColor',color(iBasin,:));
        end
        legendName(length(matchingMethodList)*(iBasin-1)+i) ...
        = sprintf("%s %s",basinList(iBasin),matchingMethodList(i));
    end
    for k = 1:nTargetEvent
        plot([p(iBasin,length(matchingMethodList)*k-1).XData, ...
              p(iBasin,length(matchingMethodList)*k).XData], ...
             [p(iBasin,length(matchingMethodList)*k-1).YData, ...
              p(iBasin,length(matchingMethodList)*k).YData], ...
             '--','Color',color(iBasin,:))
    end
end
hold off

yline([0.5 1/nCluster],':','LineWidth',1.5)
xlabel('Average total rainfall in basin [mm]')
ylim([0 1])
yticks([0,1/nCluster,0.5,1])
yticklabels([0,sprintf("1/%d",nCluster),"1/2",1])
ylabel('Average accuracy')
legend(p(1:length(basinList),1:length(matchingMethodList))',legendName, ...
       'Location','northeastoutside');
fontsize(14,"points")