%%% 1.d4PDF_5kmDDS_JPのrain.ncファイルから1年間の1時間降水量を抽出 %%%
%%% 2.指定した流域の年最大(2,3,...位)n時間雨量が発生した初期時刻を抽出 %%%
%%% 3.2.で抽出した初期時刻におけるsubbasinの雨を抽出し寄与率を計算する %%%

% 用意する雨データ: rain.nc
% 入手先: https://search.diasjp.net/ja/dataset/d4PDF_5kmDDS_JP

% 入力: d4PDF(rain.nc), subbasinの面積, d4PDFの計算点の支配領域面積
% 出力: 寄与率, subbasinの総雨量

%% パラメータの設定
basin = 'agano'; % 流域
mstart = 1; % 雨量を抽出する最初のd4PDFのメンバー(1~12)
mend = 12; % 雨量を抽出する最後のd4PDFのメンバー(1~12,mend>=mstart)
ystart = 1950; % 雨量を抽出する最初の年(1950~2010)
yend = 2010; % 雨量を抽出する最後の年(1950~2010,yend>=ystart)
n = 72; % 求めたい最大雨量の期間(hours,3日=>72,15日=>360)
rank = 3; % 年何位までの雨量を用いるか
% d4PDF計算点の支配領域面積のデータがあるフォルダ
d4pdfAreaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% subbasinの面積のデータがあるフォルダ
subbasinAreaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% d4PDFのデータがあるフォルダ
d4pdfFolder = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\';
% 寄与率を出力するファイル
outFile = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                   'ProcessedRain','contributionRatio','d4pdf', ...
                   basin,sprintf('%dhours',n), ...
                   sprintf('%s_contributionRatio.mat',basin));

%% 寄与率を計算するために，subbasinの面積を取得
subbasinArea = readmatrix(fullfile(subbasinAreaFolder, ...
                                   sprintf('%s_subbasin.dat',basin)), ...
                          "NumHeaderLines",0);
nSubbasin = length(subbasinArea); % subbasinの数

%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
[ROW,COL] = ind2sub([550 755],1:550*755); % 行番号と列番号の取得
% 流域全体
d4pdfAreaCSV = readmatrix(fullfile(d4pdfAreaFolder, ...
                                   sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                          "NumHeaderLines",1);
id = d4pdfAreaCSV(:,1); % 通し番号
d4pdfArea = d4pdfAreaCSV(:,2); % ティーセン分割によって作られた各領域が流域と重なる面積
row = ROW(id); % 通し番号に対応する行番号
col = COL(id); % 通し番号に対応する列番号
% subbasin
subID = cell(1,nSubbasin); % 通し番号
d4pdfSubArea = cell(1,nSubbasin); % ティーセン分割によって作られた各領域が流域と重なる面積
subRow = cell(1,nSubbasin); % 通し番号に対応する行番号
subCol = cell(1,nSubbasin); % 通し番号に対応する列番号
for i = 1:nSubbasin
    d4pdfSubAreaCSV = readmatrix(fullfile(d4pdfAreaFolder, ...
                                          sprintf('%s%d_area_per_d4pdfcell.csv', ...
                                                  basin,i)), ...
                                 "NumHeaderLines",1);
    subID{i} = d4pdfSubAreaCSV(:,1);
    d4pdfSubArea{i} = d4pdfSubAreaCSV(:,2);
    subRow{i} = ROW(subID{i});
    subCol{i} = COL(subID{i});
end

%% d4PDFのデータがあるフォルダに移動
cd(d4pdfFolder)

%% 雨量の読み込み => 年最大流域平均雨量の抽出 => 寄与率の計算
% 寄与率
x = zeros((mend-mstart+1)*(yend-ystart+1)*rank,nSubbasin);
% subbasinの総雨量
subbasinTotalRain = zeros((mend-mstart+1)*(yend-ystart+1)*rank,nSubbasin);

for mem = mstart:mend
    %% メンバーmemのフォルダに移動  
    cd(sprintf('HPB_m%03d',mem))
    
    %% 年ごとに年最大雨量を抽出してdatファイルに出力
    for y = ystart:yend % year
        %% y年のフォルダに移動
        cd(num2str(y))
        cd hourly
    
        %% rain.ncの読み込み
        % 助走期間を考慮して9/1~8/31を1セットとする
        if ~leapyear(y+1) % 翌年がうるう年ではない場合
            rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8760]);
        else % 翌年がうるう年の場合
            rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8784]);
        end
        rain = squeeze(rain); % 長さ1の次元の削除
    
        %% 指定した流域の雨を抽出
        % 流域全体
        basinRain = zeros(1,numel(id),size(rain,3)); % 配列の事前割り当て
        for i = 1:numel(id)
            basinRain(1,i,:) = rain(row(i),col(i),:); % 流域の雨を抽出
        end
        basinRain = squeeze(basinRain); % 長さ1の次元の削除
        basinRain = basinRain'*d4pdfArea/sum(d4pdfArea); % 加重平均
        % subbasin
        subbasinRain = cell(1,nSubbasin); % 配列の事前割り当て
        for j = 1:nSubbasin
            subbasinRain{j} = zeros(1,numel(subID{j}),size(rain,3));
            for i = 1:numel(subID{j})
                % 流域の雨を抽出
                subbasinRain{j}(1,i,:) = rain(subRow{j}(i),subCol{j}(i),:);
            end
            subbasinRain{j} = squeeze(subbasinRain{j}); % 長さ1の次元の削除
            % 加重平均
            subbasinRain{j} = subbasinRain{j}'*d4pdfSubArea{j}/sum(d4pdfSubArea{j});
        end
    
        %% 流域全体のn時間雨量の抽出
        nHoursRain = movsum(basinRain,[0 n-1]); % n時間雨量を抽出
        nHoursRain = nHoursRain(1:end-(n-1)); % 最後のn-1時間はカット
    
        %% 年月日時のベクトルを作成
        dt = datetime(y,09,01,00,00,00,'Format','yyyy-MMdd-HH');
        for i = 1:length(basinRain)-1
            dt(i+1) = dt(i) + 1/24;
        end
    
        %% n時間雨量の1位からrank位までを抽出して寄与率を計算
        for i = 1:rank
            % n時間雨量の最大値とインデックスを取得
            [maxRain, initialNumber] = max(nHoursRain);
            % 最大n時間雨量が発生した初期時刻
            % initialTime = dt(initialNumber);

            % 上の初期時刻におけるsubBasinの雨を抽出
            subbasinMaxRain = cell(1,nSubbasin); % subbasinのn時間雨量
            for j = 1:nSubbasin
                subbasinMaxRain{j} = subbasinRain{j}(initialNumber:initialNumber+(n-1));
            end

            % 寄与率を計算
            den = 0; % 寄与率の分母
            for j = 1:nSubbasin
                den = den + sum(subbasinMaxRain{j})*subbasinArea(j);
            end        
            for j = 1:nSubbasin
                x((mem-mstart)*(yend-ystart+1)*rank+(y-ystart)*rank+i,j)...
                    = sum(subbasinMaxRain{j})*subbasinArea(j)/den;
                subbasinTotalRain((mem-mstart)*(yend-ystart+1)*rank+(y-ystart)*rank+i,j)...
                    = sum(subbasinMaxRain{j});
            end
    
            % 最大値の前後n時間のn時間雨量の値を-1にする(年2位,3位,...の雨量を抽出するため)
            if initialNumber < n
                nHoursRain(1:initialNumber+(n-1)) = -1;
            elseif initialNumber > length(nHoursRain)-(n-1)
                nHoursRain(initialNumber-(n-1):end) = -1;
            else
                nHoursRain(initialNumber-(n-1):initialNumber+(n-1)) = -1;
            end
        end
    
        %% ログを出力して2つ上の階層に移動
        fprintf('m%03d %d has run successfully at %s\n', ...
                mem,y,datetime('now','Format','MM/dd HH:mm:ss'))
        cd ../../
    end
    cd ../ % 1つ上の階層に移動
end

%% 寄与率とsubbasinの総雨量をmatファイルに保存
save(outFile,"nSubbasin","x","subbasinTotalRain");