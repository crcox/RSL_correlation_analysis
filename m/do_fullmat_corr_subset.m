function full_cor = do_fullmat_corr_subset(metadata, full_rank_target, subject, C, Cz, varargin);
    p = inputParser();
    addRequired(p, "metadata", @isstruct);
    addRequired(p, "full_rank_target", @islogical);
    addRequired(p, "subject");
    addRequired(p, "C", @isnumeric);
    addRequired(p, "Cz", @isnumeric);
    addOptional(p, "filters", [], @(x) isstring(x) || isempty(x));
    addOptional(p, "type", [], @(x) isstring(x) || isempty(x));
    addOptional(p, "label", [], @(x) isstring(x) || isempty(x));
    addOptional(p, "sim_source", [], @(x) isstring(x) || isempty(x));
    addOptional(p, "sim_metric", [], @(x) isstring(x) || isempty(x));
    addOptional(p, "subset", [], @(x) isstring(x) || isempty(x));
    parse(p, metadata, full_rank_target, subject, C, Cz, varargin{:});

    filters = p.Results.filters;
    subset  = p.Results.subset;

    m = select_by_field(metadata, struct('subject', subject));

    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end

    if isempty(subset)
        z2 = true(m.nrow, 1);
    else
        z2 = get_row_filter(m.filters, subset);
    end

    fprintf('%z1 (%d, %d): %d\n', size(z1, 1), size(z1, 2), nnz(z1));
    fprintf('%z2 (%d, %d): %d\n', size(z2, 1), size(z2, 2), nnz(z2));
    fprintf('%Cz (%d, %d): %d\n', size(Cz, 1), size(Cz, 2), nnz(Cz));
    Sz = Cz(z2(z1), :) * Cz(z2(z1), :)';

    if p.Results.full_rank_target
        x = struct("type", "similarity", ...
                   "label", p.Results.label, ...
                   "sim_source", regexprep(p.Results.sim_source, '_Dim[1-9]+', ''), ...
                   "sim_metric", p.Results.sim_metric);
        t = select_by_field(m.targets, x);
        S = t.target(z2 & z1, z2 & z1);
    else
        S = C(z2(z1),:) * C(z2(z1), :)';
    end

    full_cor = nrsa_corr(S, Sz);
end
