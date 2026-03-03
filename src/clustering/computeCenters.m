function centers = computeCenters(X, idx, k)
D = size(X,2);
centers = zeros(k, D);
for c = 1:k
    Xi = X(idx==c,:);
    if isempty(Xi)
        error("Empty cluster detected at c=%d. Adjust k or method.", c);
    end
    centers(c,:) = mean(Xi, 1);
end
end