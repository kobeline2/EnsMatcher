function targetTimeStr = normalizeTargetTime(cfgTargetTime)
% Normalize cfg.targetTime to 'yyyyMMddHHmm' (12 digits) string.

if isstring(cfgTargetTime) || ischar(cfgTargetTime)
    targetTimeStr = char(cfgTargetTime);
elseif isnumeric(cfgTargetTime)
    % 数値で来た場合. 小数や指数表記を避けて整数として扱う
    targetTimeStr = sprintf('%.0f', cfgTargetTime);
else
    error('Unsupported type for targetTime: %s', class(cfgTargetTime));
end

% 前後空白除去
targetTimeStr = strtrim(targetTimeStr);

% 桁数チェック(12桁を想定)
if numel(targetTimeStr) ~= 12 || any(~isstrprop(targetTimeStr, 'digit'))
    error('targetTime must be 12-digit string yyyyMMddHHmm. Got: "%s"', targetTimeStr);
end
end