function data_tbl_avg = average_over_subjects_bs(data_tbl, value_vars, nrep, window_type)
    arguments
        data_tbl table
        value_vars string
        nrep double
        window_type string = "None"
    end
    value_vars_sizes = varfun(@(x) size(x, 2), data_tbl(:, value_vars), 'OutputFormat', 'uniform');
    z = varfun(@isgrouping, data_tbl, 'OutputFormat', 'uniform');
    z = z & ~matches(data_tbl.Properties.VariableNames, ["subject", "RandomSeed", value_vars]);
    grouping_vars = data_tbl.Properties.VariableNames(z);
    func = @(subj, seed, varargin) ...
        bootstrap_group_means(nrep, subj, seed, cell2mat(varargin));
    tmp = rowfun(func, data_tbl, ...
                'GroupingVariables', grouping_vars, ...
                'InputVariables', ["subject", "RandomSeed", value_vars], ...
                'ExtractCellContents', true, ...
                'OutputFormat', "table", ...
                'OutputVariableNames', "means");
    data_tbl_avg = removevars([tmp, means2table(tmp.means, strcat(value_vars, "_mean"), value_vars_sizes)], ["means"]);
    data_tbl_avg = addvars(data_tbl_avg, repmat("bs_avg", height(data_tbl_avg), 1), 'NewVariableNames', "subject", 'Before', 1);
    switch window_type
        case {"OpeningWindow", "MovingWindow"}
            data_tbl_avg.RandomSeed = zeros(height(data_tbl_avg), 1);
            windows = unique(data_tbl_avg(:, ["WindowStart", "WindowSize"]));
            for i = 1:height(windows)
                z = (data_tbl_avg.WindowSize == windows.WindowSize(i)) & (data_tbl_avg.WindowStart == windows.WindowStart(i));
                data_tbl_avg.RandomSeed(z) = (1:nnz(z))';
            end
        otherwise
            data_tbl_avg.RandomSeed = (1:height(data_tbl_avg))';
    end
end


function z = isgrouping(x)
    z = ischar(x) || (~iscell(x) && size(x, 2) == 1);
end


function tbl = means2table(means, varnames, varsizes)
    tbl = cell2table(mat2cell(means, ones(size(means, 1), 1), varsizes), 'VariableNames', varnames);
end
