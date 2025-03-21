%%% 解析雨量のメッシュの中心点の緯度経度をncファイルに書き込み %%%

%% 解析雨量の格子点の緯度経度を取得
west = 118; % 領域の最西端の経度
east = 150; % 領域の最東端の経度
north = 48; % 領域の最北端の緯度
south = 20; % 領域の最南端の緯度
dx = 0.0125; % x(経度)方向の格子点の間隔
dy = 1/120; % y(緯度)方向の格子点の間隔

% 解析雨量の格子点の緯度経度
[lon,lat] = meshgrid(west +dx/2 : dx : east -dx/2, ...
                     north-dy/2 :-dy : south+dy/2);

% 行列→ベクトル
lon = reshape(lon',1,[]);
lat = reshape(lat',1,[]);

%% ncファイルに書き込み
nccreate("\\10.244.3.104\homes\アンサンブル予測\kaiseki\kaiseki_location.nc", ...
         "flat","Dimensions",{'dim1',1,'dim2',length(lat)})
nccreate("\\10.244.3.104\homes\アンサンブル予測\kaiseki\kaiseki_location.nc", ...
         "flon","Dimensions",{'dim1',1,'dim2',length(lon)})
ncwrite("\\10.244.3.104\homes\アンサンブル予測\kaiseki\kaiseki_location.nc", ...
        "flat",lat)
ncwrite("\\10.244.3.104\homes\アンサンブル予測\kaiseki\kaiseki_location.nc", ...
        "flon",lon)

% speedOfLight = ncread("kaiseki_location.nc","flat");