%%% 1.d4PDF_5kmDDS_JPのrain.ncファイルから1年間の1時間降水量を抽出 %%%
%%% 2.指定した流域の年最大(2,3,...位)n時間雨量およびその初期時刻を抽出 %%%
%%% 3.抽出した雨量のハイエトグラフを描画 %%%

% 用意する雨データ: rain.nc
% 入手先: https://search.diasjp.net/ja/dataset/d4PDF_5kmDDS_JP

%% パラメータの設定
basin = 'miya'; % 流域
mem = 4; % 雨量を抽出するd4PDFのメンバー(1~12)
year = 1950; % 雨量を抽出する年(1950~2010) test:basin='yahagi',mem=4,year=1995
n = 72; % 求めたい最大雨量の期間(hours,3日=>72,15日=>360)
rank = 3; % 年何位までの雨量のグラフを描きたいか
% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','geoData',basin);
% d4PDFのデータがあるフォルダ
d4pdfFolder = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP';

%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号
area = areaCSV(:,2); % ティーセン分割によって作られた各領域が流域と重なる面積
[row,col] = ind2sub([550 755],1:550*755); % 行番号と列番号の取得
row = row(id); % 通し番号に対応する行番号
col = col(id); % 通し番号に対応する列番号

%% フォルダの移動
cd(fullfile(d4pdfFolder,sprintf('HPB_m%03d',mem),num2str(year),'hourly'))
    
%% rain.ncの読み込み
% 助走期間を考慮して9/1~8/31を1セットとする
if ~leapyear(year+1) % 翌年がうるう年ではない場合
    rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8760]);
else % 翌年がうるう年の場合
    rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8784]);
end
rain = squeeze(rain); % 長さ1の次元の削除
    
%% 指定した流域の雨を抽出
localRain = zeros(1,numel(id),size(rain,3)); % 配列の事前割り当て
for i = 1:numel(id)
    localRain(1,i,:) = rain(row(i),col(i),:); % 流域の雨を抽出
end
localRain = squeeze(localRain); % 長さ1の次元の削除               
localRain = localRain'*area/sum(area); % 加重平均
    
%% n時間雨量の抽出
nHoursRain = movsum(localRain,[0 n-1]); % n時間雨量を抽出
nHoursRain = nHoursRain(1:end-(n-1)); % 最後のn-1時間はカット
    
%% 時点を表すベクトルの作成
% 年月日時のベクトルの作成
YMDH = datetime(year,09,01,00,00,00,'Format','yyyy/MM/dd-HH');
for i = 1:length(localRain)-1
    YMDH(i+1) = YMDH(i) + 1/24;
end
charYMDH = char(YMDH);

% % 年月日ベクトルの作成
% YMD = datetime(year,09,01,00,00,00,'Format','yyyy/MM/dd');
% for i = 1:length(localRain)-1
%     YMD(i+1) = YMD(i) + 1/24;
% end
% stringYMD = string(YMD);

% 月日ベクトルの作成
MD = datetime(year,09,01,00,00,00,'Format','MM/dd');
for i = 1:length(localRain)-1
    MD(i+1) = MD(i) + 1/24;
end
stringMD = string(MD);
    
%% n時間雨量の1位からrank位までを抽出
maxRain = zeros(1,rank); % 配列の事前割り当て
initialNumber = zeros(1,rank); % 配列の事前割り当て

for i = 1:rank
    % n時間雨量の最大値とインデックスを取得
    [maxRain(i), initialNumber(i)] = max(nHoursRain);

    % 最大n時間雨量の初期時刻
    initialTime(i) = YMDH(initialNumber(i));

    % 最大値の前後n時間のn時間雨量の値を-1にする(年2位,3位,...の雨量を抽出するため)
    if initialNumber(i) < n
        nHoursRain(1:initialNumber(i)+(n-1)) = -1;
    elseif initialNumber(i) > length(nHoursRain)-(n-1)
        nHoursRain(initialNumber(i)-(n-1):end) = -1;
    else
        nHoursRain(initialNumber(i)-(n-1):initialNumber(i)+(n-1)) = -1;
    end
end

%% 降水量のグラフの描画(1年間)
figure('Position', [600 500 900 200])
plot(localRain)
hold on
for i = 1:rank
    fill([initialNumber(i),initialNumber(i)+n-1,initialNumber(i)+n-1,initialNumber(i)], ...
        [0,0,30,30],[1 0.5 0.5],FaceAlpha=0.6,EdgeColor='none') % ハッチング
end
hold off
fontname("Arial")
fontsize(12,"points")
xlim([1 length(localRain)])
ylim([0 30])
ylabel('Precipitation [mm/h]')
if ~leapyear(year+1) % 翌年がうるう年ではない場合
    xticks([1 721 1465 2185 2929 3673 4345 5089 5809 6553 7273 8017])
    xticklabels(stringMD([1 721 1465 2185 2929 3673 4345 5089 5809 6553 7273 8017]))
else % 翌年がうるう年の場合
    xticks([1 721 1465 2185 2929 3673 4369 5113 5833 6577 7297 8041 8784])
    xticklabels(stringMD([1 721 1465 2185 2929 3673 4369 5113 5833 6577 7297 8041]))
end

%% 降水量のグラフの描画(n時間)
for i = 1:rank
    figure('Position', [200+350*i 200 300 200])
    bar(localRain(initialNumber(i):initialNumber(i)+n-1))
    fontname("Arial")
    fontsize(10.5,"points")
    ylim([0 30])
    ylabel('Precipitation [mm/h]')

    h = str2double(charYMDH(initialNumber(i),end-1:end)); % 時刻を取得
    if h == 0
        xticks(0.5:24:n-23.5)
        xticklabels(stringMD(initialNumber(i):24:initialNumber(i)+n-24))
    else
        xticks(24.5-h:24:n+0.5)
        xticklabels(stringMD(initialNumber(i)+24:24:initialNumber(i)+n))
    end
end