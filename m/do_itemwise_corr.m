function tbl_cor = do_itemwise_corr(metadata, full_rank_target, subject, C, Cz, varargin)
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
    addOptional(p, "CategoryLabels", [], @(x) isstring(x) || isempty(x));
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
    k = length(p.Results.CategoryLabels);
    Z = false(k, m.nrow);
    category = repmat(p.Results.CategoryLabels(:), 1, m.nrow);
    for i = 1:k
        Z(i, :) = select_by_field(m.filters, struct('label', p.Results.CategoryLabels(i))).filter;
    end
    category = category(Z);

    % N.B. There is an inconsistency in how the "stimuli" metadata field is
    % implemented across datasets. This conditional preserves compatibilty.
    if isstruct(m.stimuli)
        stimulus = string({m.stimuli.stimulus});
    else
        stimulus = string(m.stimuli);
    end

    tbl = table(S(:), Sz(:), colvec(stimulus(from)), colvec(stimulus(to)), colvec(category(from)), colvec(category(to)), ...
            'VariableNames', ["S", "Sz", "stim_from", "stim_to", "category_from", "category_to"]);
    tbl.within = tbl.category_from == tbl.category_to;
    tbl = tbl(tbl.stim_from ~= tbl.stim_to, :);

    tbl_cor = rowfun(@(y, p) corr(y, p), tbl, ...
        'InputVariables', ["S", "Sz"], ...
        'GroupingVariables', "stim_from", ...
        'OutputVariableNames', "itemcor_all");

    tmp = rowfun(@(y, p) corr(y, p), tbl, ...
        'InputVariables', ["S", "Sz"], ...
        'GroupingVariables', ["stim_from", "within"], ...
        'OutputVariableNames', "cor");

    tbl_cor.itemcor_within = tmp.cor(tmp.within);
    tbl_cor.itemcor_between = tmp.cor(~tmp.within);

    tbl_cor.Properties.VariableNames{1} = 'stim_id';
    tbl_cor = join(tbl_cor, table(stimulus(:), category(:), 'VariableNames', ["stim_id", "category"]));
    tbl_cor = tbl_cor(:, ["stim_id", "category", "itemcor_all", "itemcor_within", "itemcor_between"]);
end
