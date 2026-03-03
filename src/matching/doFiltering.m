function idx = doFiltering(cfg, idx, nash, d)
switch cfg.filterMethod
    case 'none'
        idx = idx;
    case 'threshold'
        % (NS<0 && ユークリッド距離) のときはマッチングさせない
        if nash < 0 && ...
           strcmp(cfg.matchingMethod,'euclid') == 1
            idx = 0;
        % (Θ>60° && コサイン類似度) のときはマッチングさせない
        elseif -min(d) < cosd(60) && strcmp(cfg.matchingMethod,'cos') == 1
            idx = 0;
        end
end
end