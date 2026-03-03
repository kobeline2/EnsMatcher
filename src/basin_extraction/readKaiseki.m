function rain = readKaiseki(fn, ROW, COL)
%READKAISEKI Read JMA analyzed rainfall grid and convert to mm/h.
%  This function auto-detects whether the file stores uint8 levels (n bytes)
%  or int32 levels (4n bytes). Missing (level=0) is treated as 0.

fid = fopen(fn, 'rb');
assert(fid > 0, "Cannot open file: %s", fn);

n = ROW*COL;
info = dir(fn);
bytes = info.bytes;
fclose(fid);

% --- load raw levels as double vector length n ---
if bytes == n
    % uint8 level grid
    fid = fopen(fn, 'rb');
    raw = fread(fid, n, 'uint8=>double');
    fclose(fid);
elseif bytes == 4*n
    % int32 level grid (endianness may vary)
    raw = tryReadInt32Levels(fn, n);
else
    error("Unexpected file size. bytes=%d, expected=%d or %d.", bytes, n, 4*n);
end

assert(numel(raw) == n, "Unexpected read length in %s", fn);

% --- if values look like levels (0..98), convert by LUT ---
maxv = max(raw);
minv = min(raw);

if minv >= 0 && maxv <= 98 && all(abs(raw - round(raw)) < 1e-9)
    rain = levelToMmPerHour(raw);
else
    % Fallback: if the file already stores mm/h (rare in this naming), keep raw.
    % If you later confirm a scale factor (e.g., 0.1 mm/h), apply it here.
    rain = raw;
end

end

function raw = tryReadInt32Levels(fn, n)
% Try little endian then big endian, choose the one that yields plausible levels.
raw = readInt32(fn, n, 'ieee-le');
if isPlausibleLevel(raw); return; end
raw = readInt32(fn, n, 'ieee-be');
if isPlausibleLevel(raw); return; end
% If neither looks like levels, return little endian as default
% (caller will treat it as already mm/h).
raw = readInt32(fn, n, 'ieee-le');
end

function x = readInt32(fn, n, machinefmt)
fid = fopen(fn, 'rb', machinefmt);
assert(fid > 0, "Cannot open file: %s", fn);
x = fread(fid, n, 'int32=>double');
fclose(fid);
end

function tf = isPlausibleLevel(x)
tf = all(isfinite(x)) && min(x) >= 0 && max(x) <= 98 && all(abs(x-round(x))<1e-9);
end

function rain = levelToMmPerHour(level)
% level: double vector, integer 0..98
lut = nan(256,1);
lut(0+1) = 0;     % missing -> 0
lut(1+1) = 0;     % 0 mm/h
lut(2+1) = 0.4;   % 0.4 mm/h
for lv = 3:79
    lut(lv+1) = lv - 2;
end
for lv = 80:90
    lut(lv+1) = 80 + (lv-80)*5;
end
for lv = 91:97
    lut(lv+1) = 140 + (lv-91)*10;
end
lut(98+1) = 255;

rain = lut(level+1);
end