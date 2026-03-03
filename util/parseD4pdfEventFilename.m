function [member, startStr, totalMm] = parseD4pdfEventFilename(name)
%PARSED4PDFEVENTFILENAME
% expected: m002_1953-0819-02_255mm.dat
member = "";
startStr = "";
totalMm = NaN;

s = erase(string(name), ".dat");
parts = split(s, "_");
if numel(parts) >= 3
    member   = parts(1);
    startStr = parts(2);

    mmStr = parts(3);
    mmStr = erase(mmStr, "mm");
    val = str2double(mmStr);
    if ~isnan(val); totalMm = val; end
end
end