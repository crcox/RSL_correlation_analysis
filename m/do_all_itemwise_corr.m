function cell_tbl_cor = do_all_itemwise_corr(metadata, full_rank_target, results)
    p = inputParser();
    addRequired(p, 'metadata', @isstruct);
    addRequired(p, 'full_rank_target', @islogical);
    addRequired(p, 'results', @istable);
    parse(p, metadata, full_rank_target, results);

    vars = ["subject", "C", "Cz", "filters", "target_type", "target_label", "sim_source", "sim_metric"];
    func = @(varargin) do_itemwise_corr(metadata, full_rank_target, varargin{:});
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
