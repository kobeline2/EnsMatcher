%%% アメダスの観測値から流域平均雨量を計算 %%%
%%% subbasinの寄与率を計算 %%%

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
amedasAreaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測\QGIS',basin);
% subbasinの面積のデータがあるフォルダ
subbasinAreaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測\QGIS',basin);
% アメダス雨量のデータがあるフォルダ
amedasFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測\amedas', ...
                        basin,sprintf('%dhours',h));
% 寄与率を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'ProcessedRain\contributionRatio\amedas', ...
                   basin,sprintf('%dhours',h), ...
                   sprintf('%s_%04d%02d%02d%02d00.mat',basin,Y,M,D,H));

%% 寄与率を計算するために，subbasinの面積を取得
subbasinArea = readmatrix(fullfile(subbasinAreaFolder, ...
                                   sprintf('%s_subbasin.dat',basin)), ...
                          "NumHeaderLines",0);
nSubbasin = length(subbasinArea); % subbasinの数

%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
% subbasin
subID = cell(1,nSubbasin); % 通し番号
amedasSubArea = cell(1,nSubbasin); % ティーセン分割によって作られた各領域が流域と重なる面積
for i = 1:nSubbasin
    amedasSubAreaCSV = readmatrix(fullfile(amedasAreaFolder, ...
                                  sprintf('%s%d_area_per_amedascell.dat', ...
                                          basin,i)));
    subID{i} = amedasSubAreaCSV(:,1);
    amedasSubArea{i} = amedasSubAreaCSV(:,3);
end

%% アメダス雨量の読み込み
rainFile = fullfile(amedasFolder,sprintf('%04d%02d%02d%02d00.csv',Y,M,D,H));
rain = readmatrix(rainFile,'NumHeaderLines',1,'Delimiter',',');

%% 加重平均
subbasinRain = cell(1,nSubbasin); % subbasinの1時間ごとの平均雨量
for i = 1:nSubbasin
    subbasinRain{i} = rain*amedasSubArea{i}/sum(amedasSubArea{i});
end

%% 寄与率を計算
amedasX = zeros(1,nSubbasin); % 寄与率
subbasinTotalRain = zeros(1,nSubbasin); % subbasinの総雨量
den = 0; % 寄与率の分母
for i = 1:nSubbasin
    den = den + sum(subbasinRain{i})*subbasinArea(i);
end        
for i = 1:nSubbasin
    amedasX(i) = sum(subbasinRain{i})*subbasinArea(i)/den;
    subbasinTotalRain(i) = sum(subbasinRain{i});
end

%% 寄与率をmatファイルに保存
save(outFile,"amedasX");