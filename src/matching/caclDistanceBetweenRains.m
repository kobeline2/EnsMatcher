function d = caclDistanceBetweenRains(x, y, method)

switch method
    case 'euclid' % (1)ユークリッド距離
        % d4PDFの各クラスターの重心とアメダスの間のユークリッド距離を計算
        d = norm(x - y);
    case 'cos' % (2)コサイン類似度
        % d4PDFの各クラスターの重心とアメダスが作る角度の余弦を計算
        d = -cos(subspace(x, y));
end
end