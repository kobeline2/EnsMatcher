function [segments, startIndices, windowSumsOut] = extractTopNonOverlappingSegments(x, L, M)
% extractTopNonOverlappingSegments Extracts the top M non-overlapping segments from x.
%
%   [segments, startIndices, windowSumsOut] = extractTopNonOverlappingSegments(x, L, M)
%
% INPUTS:
%   x - A numeric vector of length N.
%   L - The length of each contiguous segment.
%   M - The number of non-overlapping segments to extract.
%
% OUTPUTS:
%   segments     - A matrix of size m x L (with m <= M), where each row is a segment from x.
%   startIndices - A vector of the starting indices (in x) of the extracted segments.
%   windowSumsOut- A vector containing the sum over each extracted segment.
%
% The function computes the sum for every contiguous window of length L (using conv),
% then selects the window with the maximum sum, excludes all windows that overlap with it,
% and repeats until M segments have been selected (or no more candidates remain).
%
% Example:
%   x = rand(1, 8760); % 1時間ごとの1年分のデータ
%   L = 72;            % 72時間（3日間）のウィンドウ
%   M = 5;             % 上位5つのイベントを抽出
%   [segments, idx, sums] = extractTopNonOverlappingSegments(x, L, M);
%   % segments は 5 x 72 の行列、idx は各イベントの開始時刻のインデックス、sums は各区間の総和

    % 入力チェック
    N = length(x);
    if L > N
        error('Segment length L (%d) exceeds length of x (%d).', L, N);
    end

    % Compute the sum for every contiguous segment (window) of length L.
    % Using 'valid' yields a vector of length (N - L + 1)
    windowSums = movsum(x, [L-1 0], 'Endpoints', 'discard');
    
    % Candidate starting indices for segments (each corresponds to a window in x)
    candidateIndices = 1:(N - L + 1);
    
    selectedIndices = []; % To store chosen starting indices
    
    % Greedy selection: iterate up to M times
    for m = 1:M
        if isempty(candidateIndices)
            break;  % No more candidates remain
        end
        
        % Find the candidate with the maximum window sum
        [~, idxRelative] = max(windowSums(candidateIndices));
        bestIdx = candidateIndices(idxRelative);
        selectedIndices(end+1) = bestIdx; %#ok<AGROW>
        
        % Exclude all candidate indices that would produce overlapping segments.
        % Two segments starting at i and j are non-overlapping if |i - j| >= L.
        candidateIndices(abs(candidateIndices - bestIdx) < L) = [];
    end
    
    % Optionally, sort the selected indices in ascending order (chronological order)
    selectedIndices = sort(selectedIndices);
    
    % Extract the segments and corresponding window sums.
    numSelected = length(selectedIndices);
    segments = zeros(numSelected, L);
    windowSumsOut = zeros(numSelected, 1);
    for i = 1:numSelected
        idx = selectedIndices(i);
        segments(i, :) = x(idx:idx+L-1);
        windowSumsOut(i) = windowSums(idx);
    end
    
    startIndices = selectedIndices;

    % sort the data in descending
    [windowSumsOut, idx] = sort(windowSumsOut, 'descend');
    startIndices = startIndices(idx)';
    segments = segments(idx, :);
end