function full_cor = do_fullmat_corr(metadata, full_rank_target, subject, C, Cz, varargin);
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
    parse(p, metadata, full_rank_target, subject, C, Cz, varargin{:});

    filters = p.Results.filters;

    m = select_by_field(metadata, struct('subject', subject));
    Sz = Cz * Cz';
    if p.Results.full_rank_target
        x = struct("type", "similarity", ...
                   "label", p.Results.label, ...
                   "sim_source", regexprep(p.Results.sim_source, '_Dim[1-9]+', ''), ...
                   "sim_metric", p.Results.sim_metric);
        t = select_by_field(m.targets, x);
        S = t.target;
    else
        S = C * C';
    end

    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end

    if p.Results.full_rank_target
        S = S(z1, z1);
    end

    full_cor = nrsa_corr(S, Sz);
end
