function x = bootstrap_group_means(nrep, subjects, random_seeds, data, varargin)
    p = inputParser();
    addRequired(p, 'nrep', @isscalar);
    addRequired(p, 'subjects', @isnumeric);
    addRequired(p, 'random_seeds', @isnumeric);
    addRequired(p, 'data', @isnumeric);
    addParameter(p, 'OutputFormat', @isstring);
    addParameter(p, 'OutputVariableNames', @isstring);
    parse(p, nrep, subjects, random_seeds, data, varargin{:});

    nsubj = length(unique(subjects));
    nperm = length(unique(random_seeds));
    keys = [subjects(:), random_seeds(:)];
    rand_match = @() [(1:nsubj)', randi(nperm, nsubj, 1)];
    rand_samp = @(x) x(ismember(keys, rand_match(), 'rows'), :);

    fun = @() mean(rand_samp(data));

    if exists_parpool()
        tmp = par_replicate(nrep, fun);
    else
        tmp = replicate(nrep, fun);
    end
    x = cat(1, tmp{:});
end
