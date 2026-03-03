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
    info = ncinfo(fn);
    nLon = info.Dimensions(2).Length;
    nLat = info.Dimensions(3).Length;
    numHourInYear = 8760 + 24 * isLeapYear(iYear+1);
    rain = ncread(fn, 'rain', ...
                  [1,   1,   1, 929], ...
                  [Inf, Inf, 1, numHourInYear]);
    rain = squeeze(rain); 
    rain = reshape(rain, [nLon*nLat, numHourInYear]);
    rain = rain(cellId, :);
    % 欠測は無い仕様なのでチェック
    assert(~any(isnan(rain(:))), 'NaN detected in rain. Check data specification.');

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