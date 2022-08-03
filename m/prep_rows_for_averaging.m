function tbl = prep_rows_for_averaging(tbl, meta_tbl)
    % The preparation function does two things:
    % 1. Ensure all matrices of predictions are the same size. They may not be
    %    the same size if rows were censored from the neuroimaging data (an
    %    items x neural features matrix). The NaNs are inserted for the missing
    %    predictions.
    % 2. Sort the combined predicted embeddings to be alphabetical by stimulus
    %    label to ensure that averages are computed over corresponding items.
    meta_vars = removevars(meta_tbl, ["metadata", "metadata_varname"]).Properties.VariableNames;
    meta_vars = meta_vars(ismember(meta_vars, tbl.Properties.VariableNames));
    for i = 1:height(tbl)
        tmp = tbl(i, meta_vars);
        tmp = join(tmp, meta_tbl);
        m = select_by_field(tmp.metadata, struct('subject', tbl.subject(i)));

        if isempty(tbl.filters{i})
            z1 = true(m.nrow, 1);
        else
            z1 = get_row_filter(m.filters, tbl.filters{i});
        end

        x = nan(numel(z1), size(tbl.Cz{i}, 2));
        x(z1, :) = tbl.Cz{i};

        % Sort into alphabetic stimulus order
        [~, ix] = sort(m.stimuli);
        tbl.Cz{i} = x(ix, :);
    end
end
