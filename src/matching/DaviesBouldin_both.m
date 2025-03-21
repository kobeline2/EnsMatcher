%%% Davies-Bouldin基準で適切なクラスター数を検討する(時空間分布) %%%

%% 1.パラメータの設定
% 流域
basinList = ["mogami","agano","tenryu","yahagi","miya","yodo","chikugo"];
legendName = ["Mogami","Agano","Tenryu","Yahagi","Miya","Yodo","Chikugo","mean"];

% d4PDF
h = 72; % 対象期間(hours)
nRank = 3; % 年何位までの雨量を用いるか(1~5)
% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','geoData');
% クラスタリングしたいd4PDFの雨量データがあるフォルダ
d4pdfFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                       'ProcessedRain','rainMatrix','d4pdf');
filename = '*.dat'; % 読み込みたい雨量データのファイル名

% クラスタリング評価
criterion = 'DaviesBouldin'; % 'CalinskiHarabasz'or'DaviesBouldin'
maxCluster = 10; % 作成するクラスターの最大値

%%
figure('Position',[600 200 600 400])
p = gobjects(zeros,length(basinList)+1);
colors = lines(length(basinList)); % プロットの線の色
DaviesBouldinValues = zeros(length(basinList),maxCluster);

for iBasin = 1:length(basinList)

    basin = basinList(iBasin);
    
    % ティーセン分割後の各領域のid(番号)を取得
    areaCSV = readmatrix(fullfile(areaFolder,basin, ...
                                  sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                         "NumHeaderLines",1);
    id = areaCSV(:,1); % 通し番号
    
    % d4PDF雨量データの読み込み
    rain = zeros(0,length(id)*h);
    for iRank = 1:nRank  
        datFiles = dir(fullfile(d4pdfFolder,basin,sprintf('%dhours',h), ...
                                num2str(iRank),filename));
        nDatFile = length(datFiles);
        tempRain = zeros(nDatFile,length(id)*h);
        for i = 1:nDatFile
            tempRain(i,:) = reshape(readmatrix(fullfile(datFiles(i).folder, ...
                                                        datFiles(i).name)), ...
                                    [1,length(id)*h]);
        end
        rain = vertcat(rain,tempRain); % 行列を連結
    end
    
    % evalclusters
    eva = evalclusters(rain,'linkage',criterion,'KList',1:maxCluster);
    % 最小値とそのインデックスを取得
    % [minValue, minIndex] = min(eva.CriterionValues);
    
    % DaviesBouldin Valuesをplot
    p(iBasin) = plot(eva.CriterionValues,'Color',colors(iBasin,:),'LineWidth',1);
    hold on
    % plot(minIndex,minValue,'rsquare','MarkerSize',10,'MarkerFaceColor','r');

    % DaviesBouldin Valuesを取得
    DaviesBouldinValues(iBasin,:) = eva.CriterionValues;

end

% 平均値をplot
meanDaviesBouldinValues = mean(DaviesBouldinValues);
[minValue, minIndex] = min(meanDaviesBouldinValues);
p(length(basinList)+1) = plot(mean(DaviesBouldinValues),'--k','LineWidth',2);
% 最小値にマーカーをplot
plot(minIndex,minValue,'rsquare','MarkerSize',10,'MarkerFaceColor','r');

hold off
xlim([2 10])
xlabel('Number of clusters')
ylim([2.5 5])
ylabel('Davies-Bouldin index')
ytickformat('%.1f')
lgd = legend(p,legendName);
lgd.NumColumns = 2; % 凡例の列数
fontname('Arial')
fontsize(12,'points')