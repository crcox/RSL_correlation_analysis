function [x,r] = bootstrap_predicted_embeddings(nrep, subjects, random_seeds, data, varargin)
    p = inputParser();
    addRequired(p, 'nrep', @isscalar);
    addRequired(p, 'subjects', @isnumeric);
    addRequired(p, 'random_seeds', @isnumeric);
    addRequired(p, 'data', @iscell);
    addParameter(p, 'OutputFormat', @isstring);
    addParameter(p, 'OutputVariableNames', @isstring);
    parse(p, nrep, subjects, random_seeds, data, varargin{:});

    nsubj = length(unique(subjects));
    nperm = length(unique(random_seeds));
    nitems = max(cellfun(@(x) size(x, 1), data));
    ndim = max(cellfun(@(x) size(x, 2), data));
    keys = [subjects(:), random_seeds(:)];
    rand_match = @() [(1:nsubj)', randi(nperm, nsubj, 1)];
    rand_samp = @(x) x(ismember(keys, rand_match(), 'rows'));
    fun = @(x) {nanmean(reshape(cell2mat(rand_samp(data)), nitems, ndim, nsubj), 3)};

    if exists_parpool()
        tmp = par_replicate(nrep, fun);
    else
        tmp = replicate(nrep, fun);
    end
    x = cat(1, tmp{:});
    r = (1:nrep)';
end
