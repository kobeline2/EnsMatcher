function rain = fetchBasinD4pdfRain(const, cfg, memberDir, iYear, cellId)
% D4PDFデータを読んで, 流域の雨を抽出する.
% ただし, すでに流域抽出後のD4PDFデータがd4pdfBasinFnにあるならそちらをよむ. 
% ない場合は, 計算するが, cfg.saveD4pdfbasinRainによって, 流域抽出後のD4PDFデータを
% d4pdfBasinFnに保存するか選ぶことができる.


[parentPath, ~, ~] = fileparts(const.path.d4pdf);
d4pdfBasinPath = fullfile(parentPath, cfg.basin);
d4pdfBasinFn = fullfile(d4pdfBasinPath, memberDir, num2str(iYear), 'hourly', 'rain.mat');

% matファイルがすでに存在したら, そちらを読む
if exist(d4pdfBasinFn, 'file')
    rain = load(d4pdfBasinFn);
    fn = fieldnames(rain);
    rain = rain.(fn{1});
else
    % なければ, rain.ncを読んで流域領域を切り出す
    fn = fullfile(const.path.d4pdf, memberDir, num2str(iYear), 'hourly', 'rain.nc');
    numHourInYear = 8760 + 24*leapyear(iYear+1);
    rain = ncread(fn, 'rain', ...
                  [1,   1,   1, 929], ...
                  [Inf, Inf, 1, numHourInYear]);
    rain = squeeze(rain); % 長さ1の次元の削除
    rain = reshape(rain, [550*755, numHourInYear]);
    rain = rain(cellId, :);
    % 保存したかったらmat形式で保存(single, v7で軽量化を図っている)
    if cfg.saveD4pdfbasinRain
        rain = single(rain);
        if ~exist(fileparts(d4pdfBasinFn), 'dir')
            mkdir(fileparts(d4pdfBasinFn));
        end
        save(d4pdfBasinFn, 'rain', '-v7');
    end
end

end