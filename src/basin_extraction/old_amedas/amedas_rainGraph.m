%%% アメダス観測雨量のグラフの描画 %%%

%% 雨量データの読み込み
filename = ['\\10.244.3.104\homes\アンサンブル予測\' ...
            'ProcessedRain\nHoursRain\amedas\' ...
            'miya\72hours\miya_201710200900.dat'];
rain = readmatrix(filename);

%% 年月日ベクトルの作成
dt = filename(end-15:end-4); % filenameから初期時刻の年月日を取得
dt = datetime(str2double(dt(1:4)),str2double(dt(5:6)),str2double(dt(7:8)), ...
              'Format','MM/dd');
for i = 1:length(rain)/24
    dt(i+1) = dt(i) + 1;
end
dt = char(dt(2:end)); % 文字配列に変換

%% グラフの描画
figure('Position', [600 500 500 150])
bar(rain)
ylim([0 30])
ylabel('rain [mm/h]','FontSize',12)
if filename(end-6) == '9' % 初期時刻が09時の場合
    xticks(15.5:24:length(rain))
elseif filename(end-6) == '1' % 初期時刻が21時の場合
    xticks(3.5:24:length(rain))
end
xticklabels(dt)
fontsize(14,"points")