%%% アンサンブル予測のcsvファイルから指定した流域のh時間雨量を抽出 %%%

% 用意する雨データ: yyyyMMddHHmm_mem.csv (アンサンブル降雨予測)
% 入手先: 一般財団法人 日本気象協会

%% パラメータの設定
basin = 'agano'; % 流域
h = 72; % 出力する雨量の期間(hours, 12<=h<=360 & mod(h,12)=0)
Y = 2022; % 対象期間の開始年
M = 8; % 対象期間の開始月
D = 2; % 対象期間の開始日
H = 21; % 対象期間の開始時(9 or 21)
% アンサンブル雨量のデータがあるフォルダ
ensFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','ensemble',basin);
% 雨量を出力するフォルダ
outFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                     'ProcessedRain','rainMatrix','ensemble', ...
                     basin,sprintf('%dhours',h), ...
                     sprintf('%04d%02d%02d%02d00',Y,M,D,H));

%% アンサンブル予測のグリッド数を取得
rainFile = fullfile(ensFolder,sprintf('%04d%02d%02d%02d00_01.csv',Y,M,D,H));
rain = readmatrix(rainFile,'NumHeaderLines',0,'Delimiter',',');
ROW = rain(1,13); % アンサンブル予測のグリッドの行数
COL = rain(1,12); % アンサンブル予測のグリッドの列数
[row,col] = ind2sub([ROW COL],1:ROW*COL); % 行番号と列番号の取得

%% 初期時刻毎，メンバー毎にh時間の流域平均雨量を算出してdatファイルに出力
for initTimeNum = 1:31-h/12 % 初期時刻
    % 初期時刻の文字列の作成
    initTime = sprintf('%04d%02d%02d%02d00',Y,M,D,H);
    
    for mem = 1:51 % アンサンブル予測のメンバー(通常はmem = 1:51)
        % 雨量の読み込み
        rainFile = fullfile(ensFolder,sprintf('%s_%02d.csv',initTime,mem));
        rain = readmatrix(rainFile,'NumHeaderLines',0,'Delimiter',',');
        idx = find(mod(1:length(rain),ROW+1) ~= 1); % 雨量が格納されている行番号を取得
        rain = rain(idx,1:COL); % 雨量のみの行列を作成
       
        % 指定した流域の雨を抽出
        localRain = zeros(length(rain)/ROW,ROW*COL); % 配列の事前割り当て
        for j = 1:length(rain)/ROW % csvに含まれる予測時間(通常は360時間)
            for i = 1:ROW*COL
                localRain(j,i) = rain(ROW*(j-1)+row(i),col(i));
            end
        end
    
        % 流域のh時間雨量をdatファイルに出力
        filename = fullfile(outFolder, ...
                            sprintf('%s_%s_%03d.dat',basin,initTime,mem));
        writematrix(localRain(12*(initTimeNum-1)+1:12*(initTimeNum-1)+h,:)',filename)
    end
    
    % 初期時刻の更新(-12h)
    tmpDate = datetime(Y, M, D, H, 00, 00);
    tmpDate = tmpDate - hours(12);
    Y = tmpDate.Year;
    M = tmpDate.Month;
    D = tmpDate.Day;
    H = tmpDate.Hour;

end