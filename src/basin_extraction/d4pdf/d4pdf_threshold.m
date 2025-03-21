%%% d4PDFの年最大流域平均雨量の中央値を計算する %%%

%% 1.パラメータの設定
basin = 'miya'; % 流域
h = 72; % 対象期間(hours)
% d4PDFの雨量データがあるフォルダ
d4pdfFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                       'ProcessedRain','nHoursRain','d4pdf', ...
                       basin,sprintf('%dhours',h));
filename = '*.dat'; % 読み込みたい雨量データのファイル名

%% 2.d4PDF雨量データの読み込み
% 'd4pdfFolder\1位\ファイル名'
datFiles = dir(fullfile(d4pdfFolder,'1',filename));
nDatFile = length(datFiles);
rain = zeros(nDatFile,h);
for i = 1:nDatFile
    rain(i,:) = readmatrix(fullfile(datFiles(i).folder,datFiles(i).name));
end

%% 3.年最大流域平均雨量の中央値を計算
totalRain = sum(rain,2);
medianRain = median(totalRain);