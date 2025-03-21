%%% 1.d4PDF_5kmDDS_JPのrain.ncファイルから1年間の1時間降水量を抽出 %%%
%%% 2.指定した流域の年最大(2,3,...位)n時間雨量およびその初期時刻を抽出 %%%
%%% 3.抽出した雨の動画を作成 %%%

%% パラメータの設定
basin = 'miya'; % 流域
mem = 4; % 雨量を抽出するd4PDFのメンバー(1~12)
year = 1950; % 雨量を抽出する年(1950~2010)
n = 72; % 求めたい最大雨量の期間(hours,3日=>72,15日=>360)
nRank = 3; % 年何位までの雨量が欲しいか
% d4PDF計算点の支配領域面積のデータがあるフォルダ
areaFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測','geoData',basin);
% d4PDFの計算点の緯度経度の情報が入ったCSVファイル
locationFile = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\cnst\location.csv';
% d4PDFのデータがあるフォルダ
d4pdfFolder = '\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP';
d4pdfFile = fullfile('\\10.244.3.104\homes\アンサンブル予測','d4PDF','d4PDF_5kmDDS_JP', ...
                     sprintf('HPB_m%03d',mem),num2str(year),'hourly','rain.nc');
% 出力する動画ファイルを置くフォルダ
outMovieFolder = fullfile('\\10.244.3.104\homes\アンサンブル予測', ...
                        'Movie',basin,'d4pdf',sprintf('%dhours',n));


%% d4PDFの計算点の位置情報を取得(加重平均の計算とresamplingの準備)
% basinを覆う計算点の番号を取得
areaCSV = readmatrix(fullfile(areaFolder, ...
                              sprintf('%s_area_per_d4pdfcell.csv',basin)), ...
                     "NumHeaderLines",1);
id = areaCSV(:,1); % 通し番号
area = areaCSV(:,2); % ティーセン分割によって作られた各領域が流域と重なる面積
[row,col] = ind2sub([550 755],1:550*755); % 行番号と列番号の取得
row = row(id); % 通し番号に対応する行番号
col = col(id); % 通し番号に対応する列番号

% 計算点の緯度経度を取得
locationCSV = readmatrix(locationFile,"NumHeaderLines",1);
d4pdfLon = locationCSV(id,5); % 経度
d4pdfLat = locationCSV(id,4); % 緯度


%% 雨量の読み込み → 流域雨量の抽出   
% rain.ncの読み込み
% 助走期間を考慮して9/1~8/31を1セットとする
if ~leapyear(year+1) % 翌年がうるう年ではない場合
    rain = ncread(d4pdfFile,'rain',[1 1 1 929],[Inf Inf 1 8760]);
else % 翌年がうるう年の場合
    rain = ncread(d4pdfFile,'rain',[1 1 1 929],[Inf Inf 1 8784]);
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
dt = datetime(year,09,01,00,00,00,'Format','MM/dd HH:mm');
for i = 1:length(meanBasinRain)-1
    dt(i+1) = dt(i) + 1/24;
end


%% n時間雨量の1位からrank位までを抽出して動画を作成
for iRank = 1:nRank
    % n時間雨量の最大値のインデックスを取得
    [~, initialNumber] = max(nHoursRain);
    % 最大n時間雨量が発生した初期時刻
    initialTime = dt(initialNumber);    
    % n時間の雨を抽出
    maxBasinRain = basinRain(:,initialNumber:initialNumber+(n-1));


    % 地図に色塗り→動画作成
    % 国土地理院の白地図を読み込み
    basemapName = "GSImap";
    url = "https://cyberjapandata.gsi.go.jp/xyz/blank/{z}/{x}/{y}.png"; 
    attribution = ".";
    % attribution = "国土地理院発行の白地図を加工して作成";
    addCustomBasemap(basemapName,url,"Attribution",attribution)
    
    % colorbarの設定
    maxMeanRain = max(maxBasinRain,[],"all"); % meanRainの最大値
    minMeanRain = min(maxBasinRain,[],"all"); % meanRainの最小値
    intervalTickLabels = 10; % 目盛りの最小単位(mm)
    maxTickLabels = ceil(maxMeanRain/intervalTickLabels) ...
                    *intervalTickLabels; % 目盛りの最大値
    minTickLabels = floor(minMeanRain/intervalTickLabels) ...
                    *intervalTickLabels; % 目盛りの最小値
    
    % 動画の設定
    video = VideoWriter(fullfile(outMovieFolder, ...
                                 sprintf('%s_d4pdf_mem%03d_%d_%d位.mp4', ...
                                         basin,mem,year,iRank)), ...
                        'MPEG-4');
    video.FrameRate = 6;
    open(video);
    
    % 地図に色塗り
    color = turbo; % カラーマップ(color = flip(gray))
    for time = 1:n
        fig = figure('Position',[500 200 300 250], ...
                     'Visible','off'); % 3列目が幅，4列目が高さ
        fig.Color = 'white';
        % gx = geoaxes('Basemap','GSImap'); % 国土地理院発行の白地図
        gx = geoaxes('Basemap','bluegreen'); % MATLABの緑青地図
        for i = 1:length(id)
            facecolor = color(round((maxBasinRain(length(id)*(time-1)+i) ...
                                     -minTickLabels) ...
                                    /(maxTickLabels-minTickLabels) ...
                                    *(size(color,1)-1)+1), ...
                              :); % 塗りつぶしの色
            gp = geoplot(d4pdfLat(i),d4pdfLon(i),'o');
            gp.MarkerFaceColor = facecolor;
            gp.MarkerEdgeColor = 'none';
            hold on          
        end
        hold off
        % 凡例をつける
        colormap(color)
        cb = colorbar;
        cb.Ticks = linspace(0,1,3);
        cb.TickLabels = {sprintf('%d mm/h',minTickLabels), ...
                         sprintf('%d',mean([minTickLabels,maxTickLabels])), ...
                         sprintf('%d',maxTickLabels)};

        % gx.ZoomLevel = 8;
        gx.Grid = "off";
        gx.LatitudeAxis.Visible = 'off';
        gx.LongitudeAxis.Visible = 'off';
        gx.LatitudeAxis.TickLabels = '';
        gx.LongitudeAxis.TickLabels = '';
        gx.Scalebar.Visible = 'off';
        gx.FontSize = 11;

        annotation('textbox',[.15 .67 .5 .2], ...
                   'String',sprintf('%s',dt(initialNumber+time)), ...
                   'EdgeColor','none','FontSize',14)
        fontname(fig,'Arial')
        frame = getframe(fig);
        writeVideo(video,frame);
        close(fig)
    end
    close(video)
    
    
    % 最大値の前後n時間のn時間雨量の値を-1にする(年2位,3位,...の雨量を抽出するため)
    if initialNumber < n
        nHoursRain(1:initialNumber+(n-1)) = -1;
    elseif initialNumber > length(nHoursRain)-(n-1)
        nHoursRain(initialNumber-(n-1):end) = -1;
    else
        nHoursRain(initialNumber-(n-1):initialNumber+(n-1)) = -1;
    end
end