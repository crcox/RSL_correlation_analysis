function write_fullmat_corr(results, filename)
    x = results.Properties.VariableNames;
    vars = [x(contains(x, "Window")), "target_label", "sim_source", "sim_metric", "subject", "RandomSeed", "fullmat"];
    tbl = results(:, vars);
    vars = replace(vars, "WindowStart", "window_start");
    vars = replace(vars, "WindowSize", "window_size");
    vars = replace(vars, "RandomSeed", "random_seed");
    tbl.Properties.VariableNames = vars;
    writetable(tbl, filename);
end
