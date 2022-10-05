function itemwise_corr_means = get_itemwise_corr_means(itemwise)
    func = @(x) varfun(@mean, x, ...
        'InputVariables', ["corr_all", "corr_within", "corr_between"]);
    tmp = cellfun(func, itemwise, 'UniformOutput', false);
    tbl_all = cat(1, tmp{:});
    tbl_all.Properties.VariableNames = ...
        ["corr_all_all", "corr_within_all", "corr_between_all"];

    func = @(x) varfun(@mean, x, ...
        'InputVariables', ["corr_all", "corr_within", "corr_between"], ...
        'GroupingVariables', "category");
    tmp = cellfun(func, itemwise, 'UniformOutput', false);
    tbl = cat(1, tmp{:});
    category_labels = unique(tbl.category);
    k = length(category_labels);
    cell_tbl_cats = cell(1, k);
    for i = 1:k
        cell_tbl_cats{i} = removevars(tbl(tbl.category == category_labels(i), :), ["category", "GroupCount"]);
        cell_tbl_cats{i}.Properties.VariableNames = ["corr_all_", "corr_within_", "corr_between_"] + category_labels(i);
    end
    itemwise_corr_means = cat(2, tbl_all, cell_tbl_cats{:});
end
