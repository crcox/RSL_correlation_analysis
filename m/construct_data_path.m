%CONSTRUCT_DATA_PATH Construct a path string from data elements
%
% Data are stored in a hierarchical structure of directories on the file system
% following some conventions. These conventions are not currently referencing
% any standard; this function may not be portable.
%
% SYNTAX
%    [path] = construct_data_path(analaysis, window_baseline, boxcar, window_start, window_size);
%    [path] = construct_data_path(analaysis, window_baseline, boxcar, window_start, window_size, root);
%
% INPUT
%    analysis: string specifying the analysis code.
%    boxcar: integer specifying the boxcar averaging size.
%    window_baseline: integer specifying the baseline window size in ms.
%    window_start: integer specifying the window onset time in ms.
%    window_size: integer specifying the window size in ms.
%    root: string specifying the path to the folder containing the "analysis"
%          folder, which is the root of the conventional path. There is a
%          hard-coded default.
%
% OUTPUT
%    A string (or string array) of paths.
%
% EXAMPLES
%    construct_data_path("OpeningWindow", 0, 10, 0, 500)
%    construct_data_path("OpeningWindow", 0, 10, 0, 500, 'root', "path/to")
%    construct_data_path("OpeningWindow", 0, 10, 0, [500, 600], 'root', "path/to")
%    construct_data_path("OpeningWindow", 0, [10, 20], 0, [500, 600], 'root', "path/to")
%
% M-files required: none
% MAT-files required: none
%
% Author: Chris Cox
% Email: chriscox_at_lsu.edu
% Date: 2021-08-08
% Matlab ver: '9.10.0.1649659 (R2021a) Update 1'
function path = construct_data_path(analysis, window_baseline, boxcar, window_start, window_size, varargin)
    p = inputParser();
    addRequired(p, 'analysis', @isstring);
    addRequired(p, 'boxcar', @isnumeric);
    addRequired(p, 'window_baseline', @isnumeric);
    addRequired(p, 'window_start', @isnumeric);
    addRequired(p, 'window_size', @isnumeric);
    addParameter(p, 'root', "/data/chriscox/ECoG/KyotoNaming/data", @isstring);
    parse(p, analysis, boxcar, window_baseline, window_start, window_size, ...
        varargin{:});

    x = orderfields(p.Results, ["root", "analysis", "window_baseline", ...
                                "boxcar", "window_start", "window_size"]);
    longest = max(structfun(@length, x));
    x = structfun(@colvec, x, 'UniformOutput', false);
    x = structfun(@(y) broadcast_singleton(y, longest), x, 'UniformOutput', false);
    tmp = rowfun(@ecog_path, struct2table(x), 'OutputVariableNames', 'path');
    path = string(tmp.path);
end

function [path] = ecog_path(root, analysis, window_baseline, boxcar, window_start, window_size)
    path = fullfile(root, analysis, ...
                   "BaselineWindow", sprintf('%04d', window_baseline), ...
                   "avg", ...
                   "BoxCar", sprintf('%03d', boxcar), ...
                   "WindowStart", sprintf('%04d', window_start), ...
                   "WindowSize", sprintf('%04d', window_size));
end

function x = broadcast_singleton(x, n)
    if length(x) == 1 && n > 1
        x = repmat(x, n, 1);
    end
end

function c = colvec(x)
    c = x(:);
end
