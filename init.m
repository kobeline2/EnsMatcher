function init()
% INIT_PATHS  Add relevant folders to MATLAB path for MyApp

    rootDir = fileparts(mfilename('fullpath'));

    % サブディレクトリ一覧
    subdirs = {
        'src/preprocessing'
        'src/basin_extraction'
        'src/matching'
        'src/evaluation'
        'util'
    };

    % 各サブディレクトリをフルパスに変換し、パスに追加
    for i = 1:length(subdirs)
        fullPath = fullfile(rootDir, subdirs{i});
        if exist(fullPath, 'dir')
            addpath(genpath(fullPath));
            fprintf('[init_paths] Added: %s\n', fullPath);
        else
            warning('[init_paths] Directory not found: %s', fullPath);
        end
    end

    fprintf('[init_paths] Initialization complete.\n');
end