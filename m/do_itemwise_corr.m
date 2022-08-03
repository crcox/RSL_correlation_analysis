function tbl_cor = do_itemwise_corr(metadata, full_rank_target, subject, C, Cz, varargin);
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

    [from, to] = meshgrid(find(z1), find(z1)); from = from(:); to = to(:);
    is_animate = select_by_field(m.filters, struct('label', 'animate')).filter;
    category = repmat("", length(is_animate), 1);
    category(is_animate) = repmat("animate", nnz(is_animate), 1);
    category(~is_animate) = repmat("inanimate", nnz(~is_animate), 1);
    stimulus = string(m.stimuli);

    tbl = table(S(:), Sz(:), stimulus(from), stimulus(to), category(from), category(to), ...
            'VariableNames', ["S", "Sz", "stim_from", "stim_to", "category_from", "category_to"]);
    tbl.within = tbl.category_from == tbl.category_to;
    tbl = tbl(tbl.stim_from ~= tbl.stim_to, :);

    tbl_cor = rowfun(@(y, p) corr(y, p), tbl, ...
        'InputVariables', ["S", "Sz"], ...
        'GroupingVariables', ["stim_from"], ...
        'OutputVariableNames', "corr_all");

    tmp = rowfun(@(y, p) corr(y, p), tbl, ...
        'InputVariables', ["S", "Sz"], ...
        'GroupingVariables', ["stim_from", "within"], ...
        'OutputVariableNames', "cor");

    tbl_cor.corr_within = tmp.cor(tmp.within);
    tbl_cor.corr_between = tmp.cor(~tmp.within);

    tbl_cor.Properties.VariableNames{1} = 'stim_id';
    tbl_cor.is_animate = ismember(tbl_cor.stim_id, stimulus(is_animate));
    tbl_cor = tbl_cor(:, ["stim_id", "is_animate", "corr_all", "corr_within", "corr_between"]);
end
