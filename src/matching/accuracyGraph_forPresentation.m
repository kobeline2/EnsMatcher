%%% 的中率の推移のグラフを描画 %%%

% パラメータの設定
projectFolder = '\\10.244.3.104\homes\アンサンブル予測'; % 研究用フォルダのパス
basinList = ["mogami","agano","tenryu","yahagi","miya","yodo","chikugo"];
% basinList = "agano";
h = 72; % 対象期間(hours)
matchingMethodList = ["euclid","cos"];
nCluster = 6;
useFilter = 1; % filterの有無(1or0)
nTargetEvent = 4; % 1流域あたりの対象イベント数
figurePosition = [10 5 11 6]; % 3列目が幅，4列目が高さ
color = lines; % plotの色
lineStyle = ["-","--"]; % plotのラインスタイル

% 的中率データの読み込み + plot
for basin = basinList
    figure('Units','centimeters','Position',figurePosition)
    p = gobjects(1,length(matchingMethodList)*nTargetEvent);
    legendName = string(zeros(1,length(matchingMethodList)*nTargetEvent));

    % 的中率データがあるフォルダ
    accuracyFolder = fullfile(projectFolder,'Result',basin, ...
                              sprintf('%dhours',h),'matching','both');
    switch useFilter
        case 1
            accuracyFolder = fullfile(accuracyFolder, ...
                                      sprintf('%dclusters_filter',nCluster));
        case 0
            accuracyFolder = fullfile(accuracyFolder, ...
                                      sprintf('%dclusters',nCluster));
        otherwise
            error('useFilter must be 1 or 0')
    end

    for i = 1:length(matchingMethodList)
        % 的中率データの読み込み
        accuracyFile = fullfile(accuracyFolder,sprintf('accuracy_%s.dat',matchingMethodList(i)));
        accuracyFileData = readmatrix(accuracyFile);
        targetEvent = num2str(accuracyFileData(:,1));
        nCorrectMember = accuracyFileData(:,3:end);
        % plot
        for j = 1:nTargetEvent
            p(2*(j-1)+i) = plot(nCorrectMember(j,:)/51, ...
                                'Color',color(j,:), ...
                                'LineStyle',lineStyle(i), ...
                                'LineWidth',2);
            hold on
            legendName(2*(j-1)+i) = sprintf("%s   %s",targetEvent(j,1:4), ...
                                                    matchingMethodList(i));
        end
    end
    yline([0.5 1/nCluster],':','LineWidth',1.5)
    % yregion(0.5,1,'FaceColor','#EDB120')
    hold off
    xlim([1 size(nCorrectMember,2)])
    xticks(1:6:size(nCorrectMember,2))
    maxLT = (size(nCorrectMember,2)-1)/2; % アンサンブルの最大リードタイム（日）
    xticklabels(string(maxLT:-3:0))
    xlabel('Lead time of ensemble forecast [day]')
    ylim([0 1])
    yticks([0,1/nCluster,0.5,1])
    yticklabels([0,sprintf("1/%d",nCluster),"1/2",1])
    ylabel('Accuracy')
    % legend(p(1:end),legendName,'Location','northeastoutside');
    fontsize(14,"points")
    set(gca,'Fontname','Arial')
end