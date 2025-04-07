function [ensLon, ensLat, ROW, COL] = fetchBasinGridEns(fn)

ensData = readmatrix(fn, 'NumHeaderLines', 0, 'Delimiter', ',');
ROW     = ensData(1,13); % アンサンブル予測のグリッドの行数
COL     = ensData(1,12); % アンサンブル予測のグリッドの列数
west    = ensData(1,14); % 最西端の経度
east    = ensData(1,16); % 最東端の経度
north   = ensData(1,15); % 最北端の緯度
south   = ensData(1,17); % 最南端の緯度
dx      = 0.0625;        % x(経度)方向のグリッドの間隔
dy      = 0.05;          % y(緯度)方向のグリッドの間隔

% アンサンブルメッシュの中心の経度緯度
[ensLon, ensLat] = meshgrid(west +dx/2 : dx : east -dx/2, ...
                           north-dy/2 :-dy : south+dy/2);

end