function write_corr3D(results, filename)
    vars = ["WindowStart", "WindowSize", "subject", "RandomSeed", "corr3D", "corr3D_ani", "corr3D_ina"];
    tbl = results(:, vars);
    tbl.Properties.VariableNames = ["window_start", "window_size", "subject", "random_seed", "corr", "corr_ani", "corr_ina"];
    writetable(tbl, filename);
end
