function [centersNew, idxNew, orderOld] = reorderByTemplateSum(centers, idx)
% orderOld(new) = old
[~, orderOld] = sort(sum(centers,2), "ascend");
centersNew = centers(orderOld,:);

k = size(centers,1);
map = zeros(k,1);
for new = 1:k
    old = orderOld(new);
    map(old) = new;
end
idxNew = map(idx);
end