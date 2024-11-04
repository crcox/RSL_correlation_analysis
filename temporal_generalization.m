function [fullmat, embedcor] = temporal_generalization(data_tbl, mw_tbl, opts)

    arguments
        data_tbl table
        mw_tbl table
        opts.cvscheme (1,1) double {mustBeInteger} = 1
        opts.scale_singular_vectors (1,1) logical = true
        opts.window_type (1,1) string {mustBeTextScalar} = "MovingWindow"
    end

    assert( ...
        opts.window_type == "MovingWindow", ...
        "Temporal generalization analysis only applies to `window_type = 'MovingWindow'`" ...
    );

    full_timer = tic();


    target_opts = table2struct(renamevars( ...
        data_tbl(1, ["target_label", "target_type", "sim_source", "sim_metric", "filters", "FiltersToApplyBeforeEmbedding"]), ...
        "FiltersToApplyBeforeEmbedding", "filters_be"...
    ));
    target_opts.scale_singular_vectors = opts.scale_singular_vectors;
    target_args = namedargs2cell(target_opts);


    data_tbl.Uz = rowfun(@sparse2dense, ...
        data_tbl, ...
        'InputVariables', ["Uz", "nz_rows"], ...
        'ExtractCellContents', true, ...
        'OutputFormat', 'cell' ...
    );


    embedcor = struct( ...
        'cv_aggregation', {'avg', 'comb'}, ...
        'all', zeros(19, 19, 3, 10), ...
        'ani', zeros(19, 19, 3, 10), ...
        'ina', zeros(19, 19, 3, 10) ...
    );
    fullmat = struct( ...
        'cv_aggregation', {'avg', 'comb'}, ...
        'all', zeros(19, 19, 10), ...
        'ani', zeros(19, 19, 10), ...
        'ina', zeros(19, 19, 10) ...
    );
    for s = 1:10
        ix = find(mw_tbl.subject == s, 1, 'first');
        cvblocks = get_cvblocks(mw_tbl.meta(ix), opts.cvscheme, s, target_opts.filters);
        embedding = get_embedding(mw_tbl.meta(ix), s, target_args{:});
        ani = get_row_filter(mw_tbl.meta(ix).filters, 'animate');
        ani2 = select_tril(ani(:) & ani(:)');
        ina2 = select_tril(~ani(:) & ~ani(:)');
        tmp_cv = zeros(19*100, 19*3, 10);
        subj_avg = zeros(19*100, 19*3);
        subj_comb = zeros(19*100, 19*3);
        for k = 1:10
            x = join( ...
                mw_tbl(mw_tbl.cvholdout == k & mw_tbl.subject == s, ["subject", "cvholdout", "window_start", "data", "meta"]), ...
                renamevars( ...
                    data_tbl(data_tbl.cvholdout == k & data_tbl.subject == s, ["subject", "cvholdout", "WindowStart", "Uz"]), ...
                    "WindowStart", "window_start" ...
                ) ...
            );
            x = sortrows(x, "window_start");
            for w = 1:height(x)
                % for each window, check if some features were filtered out
                if size(x.data{w}, 2) ~= size(x.Uz{w}, 1)
                    b_tmp = zeros(size(x.data{w}, 2), size(x.Uz{w}, 2));
                    z = x.meta(w).filters(3).filter; % colfilter
                    b_tmp(z, :) = x.Uz{w};
                    x.Uz{w} = b_tmp;
                    clear b_tmp;
                end
            end
            training_set = cvblocks ~= k;
            m = repmat(mean(embedding(training_set, :)), 1, 19);
            tmp_cv(:, :, k) = undo_normalization(cell2mat(x.data) * cell2mat(x.Uz'), m, 1);

            z = repmat(~training_set, 19, 1);
            subj_comb(z, :) = tmp_cv(z, :, k);
        end

        subj_avg(:, :) = mean(tmp_cv, 3);
        zz = repelem((1:19)', 100, 1) == repelem(1:19, 1, 3);
        subj_avg(zz) = subj_comb(zz);


        % Correlations by embedding dimension ----
        dimcol = repmat(1:3, 1, 19);
        for i = 1:3
            X = reshape(subj_avg(:, dimcol==i), 100, []);
            embedcor(1).all(:, :, i, s) = reshape(zscore(X)' * zscore(embedding(:, i)), 19, 19) / 99;
            embedcor(1).ani(:, :, i, s) = reshape(zscore(X(ani, :))' * zscore(embedding(ani, i)), 19, 19) / 99;
            embedcor(1).ina(:, :, i, s) = reshape(zscore(X(~ani, :))' * zscore(embedding(~ani, i)), 19, 19) / 99;

            X = reshape(subj_comb(:, dimcol==i), 100, []);
            embedcor(2).all(:, :, i, s) = reshape(zscore(X)' * zscore(embedding(:, i)), 19, 19) / 99;
            embedcor(2).ani(:, :, i, s) = reshape(zscore(X(ani, :))' * zscore(embedding(ani, i)), 19, 19) / 99;
            embedcor(2).ina(:, :, i, s) = reshape(zscore(X(~ani, :))' * zscore(embedding(~ani, i)), 19, 19) / 99;
        end


        % Correlations between full similarity matrices ----
        subj_avg = mat2cell(subj_avg, repelem(100, 19, 1), repelem(3, 1, 19));
        subj_avg = cellfun(@(x) select_tril(x*x'), subj_avg, 'UniformOutput', false);
        X = cell2mat(subj_avg(:)');
        S = select_tril(embedding * embedding');
        fullmat(1).all(:, :, s) = reshape(zscore(X)' * zscore(S), 19, 19) / (length(S) - 1);
        fullmat(1).ani(:, :, s) = reshape(zscore(X(ani2, :))' * zscore(S(ani2)), 19, 19) / (length(S) - 1);
        fullmat(1).ina(:, :, s) = reshape(zscore(X(ina2, :))' * zscore(S(ina2)), 19, 19) / (length(S) - 1);

        subj_comb = mat2cell(subj_comb, repelem(100, 19, 1), repelem(3, 1, 19));
        subj_comb = cellfun(@(x) select_tril(x*x'), subj_comb, 'UniformOutput', false);
        X = cell2mat(subj_comb(:)');
        fullmat(2).all(:, :, s) = reshape(zscore(X)' * zscore(S), 19, 19) / (length(S) - 1);
        fullmat(2).ani(:, :, s) = reshape(zscore(X(ani2, :))' * zscore(S(ani2)), 19, 19) / (length(S) - 1);
        fullmat(2).ina(:, :, s) = reshape(zscore(X(ina2, :))' * zscore(S(ina2)), 19, 19) / (length(S) - 1);
    end
end

function y = select_tril(x)
    n = size(x, 1);
    a = 1:n;
    z = (rot90(a + a')-1) < n;
    y = x(z);
end

