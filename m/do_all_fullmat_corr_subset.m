function cell_tbl_cor = do_all_fullmat_corr_subset(metadata, full_rank_target, results, subset)
    p = inputParser();
    addRequired(p, 'metadata', @isstruct);
    addRequired(p, 'full_rank_target', @islogical);
    addRequired(p, 'results', @istable);
    addOptional(p, 'subset', string({}), @isstring);
    parse(p, metadata, full_rank_target, results, subset);

    subset = p.Results.subset;

    vars = ["subject", "C", "Cz", "filters", "target_type", "target_label", "sim_source", "sim_metric"];
    func = @(varargin) do_fullmat_corr_subset(metadata, full_rank_target, varargin{:}, subset);
    if exists_parpool()
        cell_tbl_cor = par_rowfun(func, results, ...
                            'InputVariables', vars, ...
                            'ExtractCellContents', true, ...
                            'OutputFormat', "cell");
    else
        cell_tbl_cor = rowfun(func, results, ...
                        'InputVariables', vars, ...
                        'ExtractCellContents', true, ...
                        'OutputFormat', "cell");
    end
end
