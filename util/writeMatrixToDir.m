function writeMatrixToDir(matrix, outputDir, fileName)
% WRITEMATRIXTODIR Save a matrix to a file, creating the directory if needed.
%
%   writeMatrixToDir(matrix, outputDir, fileName)
%
% Inputs:
%   matrix    - Numeric matrix to save.
%   outputDir - Directory path where the file should be saved.
%   fileName  - File name (including extension, e.g. 'data.csv').
%
% Example:
%   A = rand(10, 10);
%   writeMatrixToDir(A, 'results/myData', 'data.csv');
%
% This function checks whether the specified directory exists. If it does
% not, it creates the directory, and then writes the matrix to the specified file.
%
% Author: Your Name
% Date: YYYY-MM-DD

    % Check if output directory exists; if not, create it.
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Combine directory and filename to form full file path.
    fullFilePath = fullfile(outputDir, fileName);

    % Write the matrix using writematrix.
    writematrix(matrix, fullFilePath);
    
    % fprintf('Matrix successfully written to: %s\n', fullFilePath);
end