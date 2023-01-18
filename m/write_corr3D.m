function write_corr3D(results, filename)
    x = results.Properties.VariableNames;
    vars = [
      x(contains(x, "Window"))
      x(matches(x, "target_label"))
      x(matches(x, "sim_source"))
      x(matches(x, "sim_metric"))
      "subject"
      "RandomSeed"
      x(contains(x, "corr3D"))
    ];
    tbl = results(:, vars);
    vars = replace(vars, "WindowStart", "window_start");
    vars = replace(vars, "WindowSize", "window_size");
    vars = replace(vars, "RandomSeed", "random_seed");
    vars = replace(vars, "corr3D", "corr");
    tbl.Properties.VariableNames = vars;
    writetable(tbl, filename);
end
