function [lon, lat, idCell] = fetchD4pdfGridInfo(cfg, const)
% basinを覆う計算点の番号を取得
fn = fullfile(const.path.geo, cfg.basin, 'area_per_d4pdfcell.csv');
idCell = readmatrix(fn, "NumHeaderLines", 1);
idCell = idCell(:, 1); % 通し番号

% 計算点の緯度経度を取得
fn = fullfile(const.path.d4pdf, 'cnst', 'location.csv');
tmp = readmatrix(fn, "NumHeaderLines", 1);
lon = tmp(idCell, 5); % 経度
lat = tmp(idCell, 4); % 緯度


end