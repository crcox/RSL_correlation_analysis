function write_fullmat_corr(results, filename)
    vars = ["WindowStart", "WindowSize", "subject", "RandomSeed", "fullmat"];
    tbl = results(:, vars);
    tbl.fullmat = cat(1, tbl.fullmat{:});
    tbl.Properties.VariableNames = ["window_start", "window_size", "subject", "random_seed", "fullmat"];
    writetable(tbl, filename);
end
