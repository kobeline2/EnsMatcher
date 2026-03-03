function events = readEventMatricesFromDir(baseDir, maxRank, nCell, nHourRain)
%READEVENTMATRICESFROMDIR
%  baseDir: .../basin/72hours
%  expects subfolders: 1..maxRank
%  each file: CSV-like .dat containing [nCell x nHourRain] (or transposed)
% 
% events 構造体のフィールド仕様
% 
% 本研究では, d4PDF から抽出した各 72h 降雨イベントを events 構造体として保持する.
% events は「クラスタリングに用いるフラット表現」と「将来の距離関数拡張(例: Wasserstein距離)に備えた分布表現」を同時に持つ.
% 
% events.x
%   型: double 配列, サイズ [Nevent x D]
%   内容: 各イベントを 1 行のベクトルとして表現した行列.
%         D = nCell * nHourRain.
%         各行は, 元の雨量行列 A [nCell x nHourRain] を MATLAB の列優先で reshape(A,1,[]) したもの.
%   用途: 本論文のクラスタリング(Ward法など)で直接利用する入力表現.
% 
% events.raw
%   型: cell 配列(長さ Nevent), 各要素は double 行列
%   内容: 各イベントの元の雨量行列 A, サイズ [nCell x nHourRain].
%         nCell は流域内の対象格子(または観測点)数, nHourRain はイベント長(72h).
%   用途: 可視化(時系列×空間の復元), および将来の距離計算で「時空間分布そのもの」を参照するための保持.
%         (例: 72h×空間の完全な時空間分布に対する Wasserstein距離など)
% 
% events.mass
%   型: double ベクトル, サイズ [Nevent x 1]
%   内容: 各イベントの総雨量(全セル×全時間の総和).
%         mass(e) = sum(events.raw{e}(:)).
%   用途: 正規化で失われる「絶対量」情報の保持.
%         将来, unbalanced optimal transport(UOT)のように総量差を許容する距離を扱う場合や,
%         形状(分布)と規模(総量)を併用した特徴設計を行う場合に利用できる.
% 
% events.prob
%   型: cell 配列(長さ Nevent), 各要素は double 行列
%   内容: 各イベントの確率分布表現(非負かつ総和=1).
%         prob{e} = raw{e} / max(mass(e), eps).
%         ここで eps はゼロ除算回避のための微小値.
%   用途: 将来の Wasserstein距離など, 分布間距離を定義する手法の入力として利用する.
%         (注) 本論文の基本解析では events.prob は使用せず, events.x を用いる.
% 
% events.info
%   型: struct(構造体), 各フィールドは長さ Nevent の配列
%   内容: 再現性確保とデバッグのために, 入力ファイルに由来するメタ情報を格納する.
%   代表的フィールド例:
%     - info.rank     : イベント抽出ランク(例: 年1位〜年5位)を表す整数
%     - info.file     : 入力ファイル名
%     - info.member   : d4PDFメンバーID(例: m002)
%     - info.startStr : イベント開始時刻を表す文字列(例: "1953-0819-02")
%     - info.totalMm  : ファイル名から読み取れる72h総雨量[mm] (取得できる場合)
%   用途: どのイベントがどのクラスターに属したかの追跡, 外れ値(異常に大きい/小さい)の検出,
%         ランク別・年別の分布確認など.
% 
% 補足(表現の整合性)
%   - events.x と events.raw は, reshape/reshape-back により互いに変換可能である.
%     すなわち, events.raw{e} を A とすると,
%       events.x(e,:) == reshape(A, 1, [])
%     が成り立つ.
%   - 逆変換は,
%       A == reshape(events.x(e,:), [nCell, nHourRain])
%     である(列優先のため MATLAB 標準の reshape で一致する).

fnFmt = '*.dat';

% pass 1: count total files
nPerRank = zeros(maxRank,1);
for r = 1:maxRank
    L = dir(fullfile(baseDir, num2str(r), fnFmt));
    nPerRank(r) = numel(L);
end
nTotal = sum(nPerRank);

D = nCell * nHourRain;
X = zeros(nTotal, D);

raw  = cell(nTotal,1);
prob = cell(nTotal,1);
mass = zeros(nTotal,1);

info = struct();
info.rank     = zeros(nTotal,1);
info.file     = strings(nTotal,1);
info.member   = strings(nTotal,1);
info.startStr = strings(nTotal,1);
info.totalStr = strings(nTotal,1); % as parsed from filename
info.totalMm  = nan(nTotal,1);     % numeric if parsable

row0 = 0;
for r = 1:maxRank
    L = dir(fullfile(baseDir, num2str(r), fnFmt));
    for i = 1:numel(L)
        e = row0 + i;
        fn = fullfile(L(i).folder, L(i).name);

        A = readmatrix(fn);

        % orientation check
        if isequal(size(A), [nHourRain, nCell])
            A = A.'; % transpose to [nCell x nHourRain]
        end

        assert(isequal(size(A), [nCell, nHourRain]), ...
            'Unexpected matrix size in %s. got %dx%d, expected %dx%d', ...
            L(i).name, size(A,1), size(A,2), nCell, nHourRain);

        assert(all(isfinite(A(:))), 'NaN/Inf found in %s', L(i).name);
        assert(all(A(:) >= 0),      'Negative rainfall found in %s', L(i).name);

        X(e,:) = reshape(A, 1, []);
        raw{e} = A;

        m = sum(A(:));
        mass(e) = m;
        prob{e} = A / max(m, eps);

        % parse filename metadata (optional but useful)
        [member, startStr, totalMm] = parseD4pdfEventFilename(L(i).name);
        info.rank(e)     = r;
        info.file(e)     = string(L(i).name);
        info.member(e)   = member;
        info.startStr(e) = startStr;
        info.totalMm(e)  = totalMm;
    end
    row0 = row0 + numel(L);
end

events = struct();
events.x    = X;        % [N x D] main input for current Ward paper
events.raw  = raw;      % cell, [nCell x 72], future OT
events.prob = prob;     % cell, normalized distributions, future OT
events.mass = mass;     % total rainfall, for unbalanced OT or hybrid features
events.info = info;     % reproducibility
end