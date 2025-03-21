%%% d4PDF_5kmDDS_JPの計算点の緯度経度をcsvに出力するコード %%%

% 用意するファイル: cnst.nc
% データの入手先: https://search.diasjp.net/ja/dataset/d4PDF_5kmDDS_JP

latitude = ncread('\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\cnst\cnst.nc','flat'); % 緯度情報の読み込み
longitude = ncread('\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\cnst\cnst.nc', 'flon'); % 経度情報の読み込み

[row,col] = ind2sub([550 755],1:numel(latitude)); % 行番号と列番号の取得

location(:,1) = 1:numel(latitude); % 通し番号
location(:,2) = row; % 行
location(:,3) = col; % 列
location(:,4) = latitude(:); % 緯度
location(:,5) = longitude(:); % 経度

Vname = {'通し番号','行','列','緯度','経度'}; % 変数名

C = [Vname;num2cell(location)]; % Vnameとlocationをcell配列として連結

writecell(C,'\\10.244.3.104\homes\アンサンブル予測\d4PDF\d4PDF_5kmDDS_JP\cnst\location.csv', ...
    'Encoding','Shift-JIS') % csvファイルに出力