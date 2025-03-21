%%% 1.d4PDF_5kmDDS_JPのrain.ncファイルから1年間の1時間降水量を抽出 %%%
%%% 2.指定した流域の年最大(2,3,...位)n時間雨量およびその初期時刻を抽出 %%%

% 用意する雨データ: rain.nc
% 入手先: https://search.diasjp.net/ja/dataset/d4PDF_5kmDDS_JP

%% パラメータの設定
basin = 'agano'; % 流域
mstart = 1; % 雨量を抽出する最初のd4PDFのメンバー(1~12)
mend = 12; % 雨量を抽出する最後のd4PDFのメンバー(1~12,mend>=mstart)
ystart = 1950; % 雨量を抽出する最初の年(1950~2010)
yend = 2010; % 雨量を抽出する最後の年(1950~2010,yend>=ystart)
n = 72; % 求めたい最大雨量の期間(hours,3日=>72,15日=>360)
rank = 5; % 年何位までの雨量が欲しいか
% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','QGIS',basin);
% d4PDFのデータがあるフォルダ
d4pdfFolder = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP';
% 雨量を出力するフォルダ
outFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                     'ProcessedRain','rainMatrix','d4pdf', ...
                     basin,sprintf('%dhours',n));

%% 加重平均を計算するために，ティーセン分割後の各領域が流域と重なる面積を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号
area = areaCSV(:,2); % ティーセン分割によって作られた各領域が流域と重なる面積
[row,col] = ind2sub([550 755],1:550*755); % 行番号と列番号の取得
row = row(id); % 通し番号に対応する行番号
col = col(id); % 通し番号に対応する列番号

%% d4PDFのデータがあるフォルダに移動
cd(d4pdfFolder)

%% 雨量の読み込み => 1時間雨量の抽出 => 最大雨量の出力
for mem = mstart:mend
    % メンバーmemのフォルダに移動  
    cd(sprintf('HPB_m%03d',mem))
    
    % 年ごとに年最大雨量を抽出してdatファイルに出力
    for y = ystart:yend % year
        % y年のフォルダに移動
        cd(num2str(y))
        cd hourly
    
        % rain.ncの読み込み
        % 助走期間を考慮して9/1~8/31を1セットとする
        if ~leapyear(y+1) % 翌年がうるう年ではない場合
            rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8760]);
        else % 翌年がうるう年の場合
            rain = ncread('rain.nc','rain',[1 1 1 929],[Inf Inf 1 8784]);
        end
        rain = squeeze(rain); % 長さ1の次元の削除
    
        % 指定した流域の雨を抽出
        basinRain = zeros(1,numel(id),size(rain,3)); % 配列の事前割り当て
        for i = 1:numel(id)
            basinRain(1,i,:) = rain(row(i),col(i),:); % 流域の雨を抽出
        end
        basinRain = squeeze(basinRain); % 長さ1の次元の削除
        meanBasinRain = basinRain'*area/sum(area); % 加重平均
    
        % n時間雨量の抽出
        nHoursRain = movsum(meanBasinRain,[0 n-1]); % n時間雨量を抽出
        nHoursRain = nHoursRain(1:end-(n-1)); % 最後のn-1時間はカット
    
        % 年月日時のベクトルを作成
        dt = datetime(y,09,01,00,00,00,'Format','yyyy-MMdd-HH');
        for i = 1:length(meanBasinRain)-1
            dt(i+1) = dt(i) + 1/24;
        end
    
        % n時間雨量の1位からrank位までを抽出して1時間ごとの雨量をdatファイルに出力
        for i = 1:rank
            % n時間雨量の最大値とインデックスを取得
            [maxRain, initialNumber] = max(nHoursRain);
            % 最大n時間雨量が発生した初期時刻
            % initialTime = dt(initialNumber);       
            
            % n時間の雨を1時間ごとに出力
            % n時間雨量の最大値をファイル名に入れる
            filename = fullfile(outFolder,num2str(i), ...
                                sprintf('%s_HPB_m%03d_%s.dat', ...
                                        basin,mem,dt(initialNumber)));
            writematrix(basinRain(:,initialNumber:initialNumber+(n-1)),filename);
    
            % 最大値の前後n時間のn時間雨量の値を-1にする(年2位,3位,...の雨量を抽出するため)
            if initialNumber < n
                nHoursRain(1:initialNumber+(n-1)) = -1;
            elseif initialNumber > length(nHoursRain)-(n-1)
                nHoursRain(initialNumber-(n-1):end) = -1;
            else
                nHoursRain(initialNumber-(n-1):initialNumber+(n-1)) = -1;
            end
        end

        % ログを出力して2つ上の階層に移動
        fprintf('m%03d %d has run successfully at %s\n', ...
                mem,y,datetime('now','Format','MM/dd HH:mm:ss'))
        cd ../../
    end
    cd ../ % 1つ上の階層に移動
end