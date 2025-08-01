%% d4pdf
fn = 'test/res/nHourRain/d4pdf/miya/72hours/1/m001_1968-1113-01_287mm.dat';
rain = readmatrix(fn);
inittime = 0;
[lon, lat, ~] = fetchD4pdfGridInfo(cfg, const);
plotRain(lon, lat, rain, 0, inittime)

%% ens
% 雨の取得
% rain = reshape(rain, [ROW, COL, 72])でもとのアンサンブルデータの形に戻る
fn = 'test/res/nHourRain/ens/miya/72hours/201709302100/201709302100_051.dat';
rain = readmatrix(fn);
inittime = datetime(2017, 09, 30, 21, 00, 00);
% 緯度経度の取得
fn = '/Volumes/koshiba/data/DAT/ensemble/miya/rep.csv';
[lon, lat, ROW, COL] = fetchBasinGridEns(fn);
lon = lon(:);
lat = lat(:);
plotRain(lon, lat, rain, 0, inittime)

%% kaiseki (resampled to d4pdf)
fn = '/Users/koshiba/Dropbox/git/EnsMatcher/test/res/nHourRain/kaiseki/miya/72hours/201709302100.dat';
rain = readmatrix(fn);
inittime = datetime(2017, 09, 30, 21, 00, 00) - hours(72);
[lon, lat, ~] = fetchD4pdfGridInfo(cfg, const);
plotRain(lon, lat, rain, 0, inittime)

%% 
function plotRain(lon, lat, rain, h, inittime)

% ── 2-1 画面設定 ─────────────────────────────
figure("Units","pixels","Position",[100 100 400 300]);
geobasemap("darkwater")              % 任意: 地図タイル
hold on

% カラーマップを固定 (例: jet)
cmap = jet(256);
colormap(cmap);

% 値範囲を決める
vmin = 0;              % 例えば 0 mm/h
vmax = max(rain(:));   % 全データの最大値
% vmax = 3; if manually specify the max value.
caxis([vmin vmax]);
cb = colorbar;
cb.Label.String = "Rainfall [mm/h]";

% scatter プロットのハンドルを初期化 (ダミーデータ)
hSc = geoscatter(lat,lon,36,zeros(size(lat)),"filled","MarkerEdgeColor","k");

if h == 0
    % ── 2-2 VideoWriter ─────────────────────────
    vout     = VideoWriter("rain_movie.mp4","MPEG-4");
    vout.FrameRate = 5;      % 1 秒間に 5 フレーム
    open(vout);
    for h = 1:size(rain,2)
        % データ更新
        set(hSc,"CData",rain(:,h));
        title(sprintf("%s", inittime+hours(h)),"FontSize",14);
    
        drawnow              % 画面更新
        frame = getframe(gcf);
        writeVideo(vout,frame);
    end
    
    close(vout);
else
    set(hSc,"CData",rain(:,h));
    title(sprintf("%s", inittime+hours(h)),"FontSize",14);
end
end