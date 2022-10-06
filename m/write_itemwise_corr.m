function write_itemwise_corr(results, filename)
    x = results.Properties.VariableNames;
    vars = [x(contains(x, "Window")), "target_label", "sim_source", "sim_metric", "subject", "RandomSeed"];
    tbl = repelem(results(:, vars), cellfun(@height, results.itemwise), 1);
    tbl = [tbl, cat(1, results.itemwise{:})];
    vars = replace(tbl.Properties.VariableNames, "WindowStart", "window_start");
    vars = replace(vars, "WindowSize", "window_size");
    vars = replace(vars, "RandomSeed", "random_seed");
    vars = replace(vars, "stim_id", "stimulus");
    tbl.Properties.VariableNames = vars;
    writetable(tbl, filename);
end
