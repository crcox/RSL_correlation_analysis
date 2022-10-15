function [fullmat, itemwise, corr3D, corr3D_avg] = correlation_analysis_ecog( ...
    final, perm, meta_tbl, analysis, full_rank_target, average_predicted_embeddings, ...
    bootstrap_averaged_embeddings, cvscheme, scale_singular_vectors)
    arguments
        final table
        perm table
        meta_tbl table
        analysis string
        full_rank_target logical = false
        average_predicted_embeddings logical = false
        bootstrap_averaged_embeddings logical = false
        cvscheme double = 1
        scale_singular_vectors logical = true
    end

    cleanupObj = onCleanup(@reset_progress_bar);
    full_timer = tic();

    %% Adjust predictions (undo normalization) ----
    % To adjust predictions, row-filters and target structures are required.
    % These are the same across all windows, so we can load a single metadata
    % file and use it to adjust all predictions.
    %
    % N.B. Adjusting the predictions for all permuted models takes ~1 minute with
    % 16 cores in parallel. Be prepared to wait if you do this without opening a
    % parpool.
    final.Cz_adj = cell(height(final), 1);
    perm.Cz_adj = cell(height(perm), 1);
    textprogressbar(sprintf('%36s', 'Adjusting predictions: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final.WindowStart == w;
                zp = perm.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final.WindowSize == w;
                zp = perm.WindowSize == w;
        end

        final.Cz_adj(zf) = colvec(adjust_all_predictions(metadata, final(zf, :), cvscheme, ...
          scale_singular_vectors));
        perm.Cz_adj(zp) = colvec(adjust_all_predictions(metadata, perm(zp, :), cvscheme, ...
          scale_singular_vectors));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));


    %% Add test-set filter to each row ----
    % To determine the test-set, row-filters and cvblocks are required.
    % These are the same across all windows, so we can load a single metadata
    % file and use it to obtain all testsets.
    % We will recycle the metadata loaded above.
    final.testset = cell(height(final), 1);
    perm.testset = cell(height(perm), 1);
    textprogressbar(sprintf('%36s', 'Add test-set filter to each row: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final.WindowStart == w;
                zp = perm.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final.WindowSize == w;
                zp = perm.WindowSize == w;
        end

        final.testset(zf) = colvec(get_all_testsets(metadata, final(zf, :), cvscheme));
        perm.testset(zp) = colvec(get_all_testsets(metadata, perm(zp, :), cvscheme ));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));


    %% Combine test-set predictions ----
    % Following the previous step where the test-set filters were added to each row
    % of the results, the metadata structure is not needed.
    final_comb = combine_all_testset_predictions(final, "Cz_adj");
    perm_comb = combine_all_testset_predictions(perm, "Cz_adj");


    %% **CONDITIONAL** Average predicted embeddings ----
    if average_predicted_embeddings
        % NEWLY IMPLEMENTED AS OF 14 JULY 2022. Not relevant to "Opening Window
        % ECoG" paper. Currently untested.
        %
        % Construct a special "avg" subject in the metadata structure that conforms
        % to these averaged predictions. Note that predictions are sorted into
        % alphabetical order by stimulus so that predictions for the same item are
        % being averaged.
        tmp = mat2cell(meta_tbl.metadata, ones(height(meta_tbl), 1), size(meta_tbl.metadata, 2));
        textprogressbar(sprintf('%36s', 'Insert average into metadata: '));
        tic;
        textprogressbar(0);
        for i = 1:height(meta_tbl)
            tmp{i} = [tmp{i}, average_metadata(tmp{i})];
            textprogressbar((i/height(meta_tbl)) * 100);
        end
        meta_tbl.metadata = cell2mat(tmp);
        textprogressbar(sprintf(' done (%.2f s)', toc));

        % The preparation function does two things:
        % 1. Ensure all matrices of predictions are the same size. They may not be
        %    the same size if rows were censored from the neuroimaging data (an
        %    items x neural features matrix). The NaNs are inserted for the missing
        %    predictions.
        % 2. Sort the combined predicted embeddings to be alphabetical by stimulus
        %    label to ensure that averages are computed over corresponding items.
        fprintf('Prepare embeddings for averaging ');
        tic;
        final_comb = prep_rows_for_averaging(final_comb, meta_tbl);
        perm_comb = prep_rows_for_averaging(perm_comb, meta_tbl);
        fprintf('(%.2f s)\n', toc);

        concat_avg = @(x) {nanmean(cat(3, x{:}), 3)}; %#ok
        tmp = rowfun( ...
            concat_avg, ... 
            final_comb, ...
            'InputVariables', "Cz", ...
            'GroupingVariables', ["WindowStart", "WindowSize"], ...
            'OutputVariableNames', "Cz" ...
        );
        fprintf('Average embeddings ');
        tic;
        final_comb = join(...
            removevars(tmp, "GroupCount"), ...
            unique(removevars(final_comb, ["Cz", "subject"])) ...
        );
        final_comb.subject = repmat("avg", height(final_comb), 1);

        if bootstrap_averaged_embeddings
            nrep = 10000;
            func = @(subj, seed, Cz) ...
                bootstrap_predicted_embeddings(nrep, subj, seed, Cz);
            tmp = rowfun(func, perm_comb, ...
                         'GroupingVariables', ["WindowStart", "WindowSize"], ...
                         'InputVariables', ["subject", "RandomSeed", "Cz"], ...
                         'OutputFormat', "table", ...
                         'OutputVariableNames', ["Cz", "RandomSeed"]);
            perm_comb = join(...
                removevars(tmp, "GroupCount"), ...
                unique(removevars(perm_comb, ["Cz", "subject", "RandomSeed"])) ...
            );
            perm_comb.subject = repmat("avg", height(perm_comb), 1);
        else
            concat_avg = @(x) {nanmean(cat(3, x{:}), 3)}; %#ok
            tmp = rowfun( ...
                concat_avg, ...
                perm_comb, ...
                'InputVariables', "Cz", ...
                'GroupingVariables', ["WindowStart", "WindowSize", "RandomSeed"], ...
                'OutputVariableNames', "Cz" ...
            );
            perm_comb = join(...
                removevars(tmp, "GroupCount"), ...
                unique(removevars(perm_comb, ["Cz", "subject"])) ...
            );
            perm_comb.subject = repmat("avg", height(perm_comb), 1);
        end
        fprintf('(%.2f s)\n', toc);

    end


    %% Add the filtered target embedding to each row ----
    final_comb.C = cell(height(final_comb), 1);
    perm_comb.C = cell(height(perm_comb), 1);
    textprogressbar(sprintf('%36s', 'Add filtered target to each row: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final_comb.WindowStart == w;
                zp = perm_comb.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final_comb.WindowSize == w;
                zp = perm_comb.WindowSize == w;
        end

        final_comb.C(zf) = colvec(get_all_embeddings(metadata, final_comb(zf, :), ...
          scale_singular_vectors));
        perm_comb.C(zp) = colvec(get_all_embeddings(metadata, perm_comb(zp, :), ...
          scale_singular_vectors));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));


    %% Compute full-matrix correlations between true and predicted sim matrices ----
    final_comb.fullmat = cell(height(final_comb), 1);
    perm_comb.fullmat = cell(height(perm_comb), 1);
    textprogressbar(sprintf('%36s', 'Full matrix correlations: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final_comb.WindowStart == w;
                zp = perm_comb.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final_comb.WindowSize == w;
                zp = perm_comb.WindowSize == w;
        end

        final_comb.fullmat(zf) = do_all_fullmat_corr(metadata, full_rank_target, final_comb(zf, :));
        perm_comb.fullmat(zp) = do_all_fullmat_corr(metadata, full_rank_target, perm_comb(zp, :));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
    fullmat = struct('final', final_comb, 'perm', perm_comb);


    %% Compute correlations between true and predicted embeddings by dimension ----
    final_comb.corr3D = zeros(height(final_comb), 3);
    final_comb.corr3D_ani = zeros(height(final_comb), 3);
    final_comb.corr3D_ina = zeros(height(final_comb), 3);
    perm_comb.corr3D = zeros(height(perm_comb), 3);
    perm_comb.corr3D_ani = zeros(height(perm_comb), 3);
    perm_comb.corr3D_ina = zeros(height(perm_comb), 3);
    textprogressbar(sprintf('%36s', 'Correlations by dimension: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final_comb.WindowStart == w;
                zp = perm_comb.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final_comb.WindowSize == w;
                zp = perm_comb.WindowSize == w;
        end

        final_comb.corr3D(zf, 1:3) = cell2mat(do_all_corr3D(metadata, final_comb(zf, :)));
        final_comb.corr3D_animate(zf, 1:3) = cell2mat(do_all_corr3D(metadata, final_comb(zf, :), "animate"));
        final_comb.corr3D_inanimate(zf, 1:3) = cell2mat(do_all_corr3D(metadata, final_comb(zf, :), "inanimate"));

        perm_comb.corr3D(zp, 1:3) = cell2mat(do_all_corr3D(metadata, perm_comb(zp, :)));
        perm_comb.corr3D_animate(zp, 1:3) = cell2mat(do_all_corr3D(metadata, perm_comb(zp, :), "animate"));
        perm_comb.corr3D_inanimate(zp, 1:3) = cell2mat(do_all_corr3D(metadata, perm_comb(zp, :), "inanimate"));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
    corr3D = struct('final', final_comb, 'perm', perm_comb);


    %% Compute itemwise correlations between true and predicted sim matrices ----
    final_comb.itemwise = cell(height(final_comb), 1);
    perm_comb.itemwise = cell(height(perm_comb), 1);
    textprogressbar(sprintf('%36s', 'Itemwise correlations: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch analysis
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                zf = final_comb.WindowStart == w;
                zp = perm_comb.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                zf = final_comb.WindowSize == w;
                zp = perm_comb.WindowSize == w;
        end

        final_comb.itemwise(zf) = do_all_itemwise_corr(metadata, full_rank_target, final_comb(zf, :), 'CategoryLabels', ["animate", "inanimate"]);
        perm_comb.itemwise(zp) = do_all_itemwise_corr(metadata, full_rank_target, perm_comb(zp, :), 'CategoryLabels', ["animate", "inanimate"]);
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
    itemwise = struct('final', final_comb, 'perm', perm_comb);


    %% Compute means over items
    fprintf('Compute means over items ');
    tic;
    final_comb = [final_comb, get_itemwise_corr_means(final_comb.itemwise)];
    perm_comb = [perm_comb, get_itemwise_corr_means(perm_comb.itemwise)];
    fprintf('(%.2f s)\n', toc);


    %% Compute group-level averages
    fprintf('Compute group-level averages ');
    vars = ["corr_all_all", "corr_within_all", "corr_between_all", ...
            "corr_all_animate", "corr_within_animate", "corr_between_animate", ...
            "corr_all_inanimate", "corr_within_inanimate", "corr_between_inanimate", ...
            "corr3D", "corr3D_animate", "corr3D_inanimate"];
    final_avg = varfun(@mean, final_comb, ...
                 'GroupingVariables', ["WindowStart", "WindowSize"], ...
                 'InputVariables', vars, ...
                 'OutputFormat', "table");
    final_avg.Properties.VariableNames = erase( ...
        string(final_avg.Properties.VariableNames), ...
        "mean_");
    final_avg.RandomSeed = zeros(height(final_avg), 1);
    final_avg.subject = repmat("avg", height(final_avg), 1);


    %% **CONDITIONAL** Bootstrap group-level averages from permutation table
    if average_predicted_embeddings
        % NEWLY IMPLEMENTED AS OF 14 JULY 2022. Not relevant to "Opening Window
        % ECoG" paper. Currently untested.
        %
        perm_avg = varfun(@mean, perm_comb, ...
                     'GroupingVariables', ["WindowStart", "WindowSize", "RandomSeed"], ...
                     'InputVariables', vars, ...
                     'OutputFormat', "table");
        perm_avg.Properties.VariableNames = erase( ...
            string(perm_avg.Properties.VariableNames), ...
            "mean_");
    else
        nrep = 10000;
        func = @(subj, seed, varargin) ...
            bootstrap_group_means(nrep, subj, seed, cell2mat(varargin));
        unpack_means = @(means, varnames) cell2table(...
            mat2cell(means, ones(size(means, 1), 1), [ones(1, 9), 3, 3, 3]), ...
        'VariableNames', varnames);
        tmp = rowfun(func, perm_comb, ...
                    'GroupingVariables', ["WindowStart", "WindowSize"], ...
                    'InputVariables', ["subject", "RandomSeed", vars], ...
                    'ExtractCellContents', true, ...
                    'OutputFormat', "table", ...
                    'OutputVariableNames', "means");
        perm_avg = removevars([tmp, unpack_means(tmp.means, vars)], ["GroupCount", "means"]);
        perm_avg.RandomSeed = zeros(height(perm_avg), 1);
        windows = unique(perm_avg(:, ["WindowStart", "WindowSize"]));
        for i = 1:height(windows)
            z = (perm_avg.WindowSize == windows.WindowSize(i)) & (perm_avg.WindowStart == windows.WindowStart(i));
            perm_avg.RandomSeed(z) = (1:nnz(z))';
        end
    end
    perm_avg.subject = repmat("bs_avg", height(perm_avg), 1);
    fprintf('(%.2f s)\n', toc);
    corr3D_avg = struct('final', final_avg, 'perm', perm_avg);
    toc(full_timer);

end

function reset_progress_bar()
    clear textprogressbar
end