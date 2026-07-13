function w = getBasinAreaWeights(cfg, const)
% Returns normalized area weights aligned to the d4PDF point order (idCell).
fn = fullfile(const.path.geo, cfg.basin, 'area_per_d4pdfcell.csv');
[~, ~, idCell] = fetchD4pdfGridInfo(cfg, const);
A = readmatrix(fn, "NumHeaderLines", 1);
assert(isequal(int32(A(:,1)), int32(idCell)), 'area_per_d4pdfcell.csv order mismatch.');

% A(:,1) is idCell (index into location.csv), A(:,2) is area
area = double(A(:,2));
assert(all(isfinite(area)) && all(area>=0), 'Invalid areas in %s', fn);

s = sum(area);
assert(s > 0, 'Sum of areas is zero in %s', fn);

w = area / s;
end