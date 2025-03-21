%%% アメダスの観測値から流域平均雨量を計算 %%%

% 用意する雨データ: yyyyMMddHHmm.csv (アメダス雨量)
% 入手先: 気象庁HP

%% パラメータの設定
basin = 'miya'; % 流域
h = 72; % 出力する雨量の期間(hours)
Y = 2023; % 対象期間の開始年
M = 6; % 対象期間の開始月
D = 1; % 対象期間の開始日
H = 9; % 対象期間の開始時(9 or 21)
% ティーセン分割後の面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% アメダス雨量のデータがあるフォルダ
amedasFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                        'amedas',basin,sprintf('%dhours',h));
% 流域平均雨量を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'ProcessedRain','nHoursRain','amedas', ...
                   basin,sprintf('%dhours',h), ...
                   sprintf('%s_%04d%02d%02d%02d00.dat',basin,Y,M,D,H));

%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_amedascell.dat',basin)));
id = areaCSV(:,1); % 通し番号
area = areaCSV(:,3); % ティーセン分割によって作られた各領域が流域と重なる面積

%% アメダス雨量の読み込み
rainFile = fullfile(amedasFolder,sprintf('%04d%02d%02d%02d00.csv',Y,M,D,H));
rain = readmatrix(rainFile,'NumHeaderLines',1,'Delimiter',',');
       
%% h時間流域平均雨量を算出してdatファイルに出力
aveRain = rain*area/sum(area); % 加重平均
writematrix(aveRain,outFile)