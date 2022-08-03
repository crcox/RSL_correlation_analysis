function x = par_rowfun(fun, tbl, varargin)
    p = inputParser();
    addRequired(p, "fun", @(x) isa(x, "function_handle"));
    addRequired(p, "tbl", @istable);
    addParameter(p, "InputVariables", [], @isstring);
    addParameter(p, "ExtractCellContents", false, @islogical);
    addParameter(p, "OutputFormat", "cell", @(x) isequal(x, "cell"));
    addParameter(p, "OutputVariableNames", [], @isstring);
    parse(p, fun, tbl, varargin{:});

    vars = p.Results.InputVariables;
    if isempty(vars)
        vars = tbl.Properties.VariableNames;
    end
    extract = p.Results.ExtractCellContents;
    outputfmt = p.Results.OutputFormat;
    outvars = p.Results.OutputVariableNames;

    x = cell(height(tbl), 1);
    [~, ix_vars] = ismember(vars, tbl.Properties.VariableNames);
    parfor i = 1:height(tbl)
        args = table2cell(tbl(i, ix_vars), 'ExtractCellContents', extract);
        try
          x{i} = fun(args{:});
        catch ME
          disp(i);
          rethrow(ME);
        end
    end
    switch p.Results.OutputFormat
        case "cell"
            out = x;
        case "table"
            out = [tbl(:, vars), table(x(:), 'VariableNames', outvars)];
    end
end
