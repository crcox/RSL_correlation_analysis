%LOAD_METADATA Load metadata from the Kyoto Naming ECoG Project
%
% In the Kyoto Naming ECoG project, metadata files exist for each data window.
% Each metadata file is similar, but some important variables will differ.
%
% INPUTS
%    analysis     : A string ("OpeningWindow" or "MovingWindow")
%    baseline_size: A number indicating the size of the baseline window in ms.
%    boxcar       : A number specifying the width of the boxcar kernel used to
%                   reduce the effective sampling rate of the data (in ms).
%    window_start : The onset of the window (from the beginning of the trial)
%                   in ms.
%    window_size  : The duration of the window in ms.
%    filename     : The name of the metadata file. Must be a .mat file.
%    varname      : The name of the variable stored in the .mat file.
%
% OUTPUTS
%    m : The structured array containing the metadata from the file.
%
% Other m-files required: construct_data_path.m
%
function m = load_metadata(analysis, baseline_size, boxcar, window_start, ...
                           window_size, filename, varname)
    path = construct_data_path(analysis, baseline_size, boxcar, ...
                               window_start, window_size);

    m = getfield(load(fullfile(path, filename)), string(varname));
end

