function testsets = get_all_testsets(metadata, results, cvscheme)
    p = inputParser();
    addRequired(p, "metadata", @isstruct);
    addRequired(p, "results", @istable);
    addRequired(p, "cvscheme", @(x) isnumeric(x) && floor(x) == x);
    parse(p, metadata, results, cvscheme);

    cvscheme = p.Results.cvscheme;

    vars = ["subject", "cvholdout", "filters"];
    fun = @(varargin) get_testset(metadata, cvscheme, varargin{:});

    if exists_parpool()
        testsets = par_rowfun(fun, results, ...
                              'InputVariables', vars, ...
                              'ExtractCellContents', true, ...
                              'OutputFormat', "cell");
    else
        testsets = rowfun(fun, results, ...
                          'InputVariables', vars, ...
                          'ExtractCellContents', true, ...
                          'OutputFormat', "cell");
    end
        %testsets = cell(height(results), 1);
        %[~, ix_vars] = ismember(vars, results.Properties.VariableNames);
        %parfor i = 1:height(results)
        %    args = table2cell(results(i, ix_vars), 'ExtractCellContents', true);
        %    testsets{i} = fun(args{:});
        %end
end
