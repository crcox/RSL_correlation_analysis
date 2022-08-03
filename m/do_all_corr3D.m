function corr3D = do_all_corr3D(metadata, results, varargin)
    p = inputParser();
    addRequired(p, 'metadata', @isstruct);
    addRequired(p, 'results', @istable);
    addOptional(p, 'subset', [], @(x) isstring(x) || isempty(x));
    parse(p, metadata, results, varargin{:});

    subset = p.Results.subset;

    vars = ["subject", "C", "Cz", "filters"];
    func = @(varargin) do_corr3D(metadata, varargin{:}, subset);
    parallel_pool = gcp('nocreate');
    if isempty(parallel_pool)
        corr3D = rowfun(func, results, ...
                        'InputVariables', vars, ...
                        'ExtractCellContents', true, ...
                        'OutputFormat', "cell");
    else
        corr3D = par_rowfun(func, results, ...
                            'InputVariables', vars, ...
                            'ExtractCellContents', true, ...
                            'OutputFormat', "cell");
    end
end
