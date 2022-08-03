function itemwise_corr_means = get_itemwise_corr_means(itemwise)
    func = @(x) varfun(@mean, x, ...
        'InputVariables', ["corr_all", "corr_within", "corr_between"]);
    tmp = cellfun(func, itemwise, 'UniformOutput', false);
    tbl_all = cat(1, tmp{:});
    tbl_all.Properties.VariableNames = ...
        ["corr_all_all", "corr_within_all", "corr_between_all"];

    func = @(x) varfun(@mean, x, ...
        'InputVariables', ["corr_all", "corr_within", "corr_between"], ...
        'GroupingVariables', "is_animate");
    tmp = cellfun(func, itemwise, 'UniformOutput', false);
    tbl = cat(1, tmp{:});
    tbl_ani = removevars(tbl(tbl.is_animate, :), ["is_animate", "GroupCount"]);
    tbl_ina = removevars(tbl(~tbl.is_animate, :), ["is_animate", "GroupCount"]);
    tbl_ani.Properties.VariableNames = ...
        ["corr_all_ani", "corr_within_ani", "corr_between_ani"];
    tbl_ina.Properties.VariableNames = ...
        ["corr_all_ina", "corr_within_ina", "corr_between_ina"];

    itemwise_corr_means = [tbl_all, tbl_ani, tbl_ina];
end
