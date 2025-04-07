function nashCoeff = calcNash(x, y)
NUM = norm(x - y)^2; % 分子
DEN = norm(x-mean(x))^2; % 分母
nashCoeff = 1 - NUM/DEN;
end