function S = loadNhourDatOnD4pdfGrid(fnDat, cfg, const, varargin)
%LOADNHOURDATOND4PDFGRID Load nCellD4 x nHour .dat and attach d4PDF lon/lat.
%
% S fields:
%   S.R      : [nCell x nHour] rainfall matrix
%   S.lon    : [nCell x 1] longitude (d4PDF point order)
%   S.lat    : [nCell x 1] latitude  (d4PDF point order)
%   S.idCell : indices/IDs for the d4PDF basin points
%   S.nCell, S.nHour
%   S.time   : [1 x nHour] datetime (optional, if cfg.targetTime exists)
%   S.meta   : struct (filename, basin, source tag)

p = inputParser;
p.addParameter('source', "", @(x)isstring(x)||ischar(x)); % "d4pdf"|"ens"|"kaiseki"
p.addParameter('timeLabel', "end", @(x)isstring(x)||ischar(x)); % "start" or "end"
p.parse(varargin{:});
opt = p.Results;

% 1) d4PDF grid points
[lonD4pdf, latD4pdf, idD4pdfcell] = fetchD4pdfGridInfo(cfg, const);
nCell = numel(idD4pdfcell);

% 2) read .dat
R = readmatrix(fnDat);
assert(~isvector(R), 'Expected matrix [nCell x nHour], got vector.');
assert(size(R,1) == nCell, 'Row mismatch: file=%d, d4pdf=%d', size(R,1), nCell);
nHour = size(R,2);

% 3) time axis (optional)
t = [];
if isfield(cfg, 'targetTime') && ~isempty(cfg.targetTime)
    targetTimeStr = normalizeTargetTime(cfg.targetTime); % 'yyyyMMddHHmm'
    tStartJST = datetime(targetTimeStr, 'InputFormat','yyyyMMddHHmm', 'TimeZone','Asia/Tokyo');
    if lower(string(opt.timeLabel)) == "start"
        % label each column by its start time (t0, t0+1h, ...)
        t = tStartJST + hours(0:nHour-1);
    else
        % label each column by its end time (t0+1h, t0+2h, ...)
        t = tStartJST + hours(1:nHour);
    end
end

% 4) pack
S = struct();
S.R = R;
S.lon = lonD4pdf(:);
S.lat = latD4pdf(:);
S.idCell = idD4pdfcell(:);
S.nCell = nCell;
S.nHour = nHour;
S.time = t;

S.meta = struct();
S.meta.fnDat = string(fnDat);
S.meta.source = string(opt.source);
S.meta.basin = string(cfg.basin);
end