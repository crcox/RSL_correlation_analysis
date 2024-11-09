function [data_tbl, meta_tbl] = prepare_data_table(data_tbl, meta_tbl, options)
    %% Adjust predictions (undo normalization) ----
    % To adjust predictions, row-filters and target structures are required.
    % These are the same across all windows, so we can load a single metadata
    % file and use it to adjust all predictions.
    %
    % N.B. Adjusting the predictions for all permuted models takes ~1 minute with
    % 16 cores in parallel. Be prepared to wait if you do this without opening a
    % parpool.
    arguments
        data_tbl table
        meta_tbl table
        options.window_type string
        options.average_predicted_embeddings logical = false
        options.bootstrap_averaged_embeddings logical = false
        options.cvscheme double = 1
        options.scale_singular_vectors logical = true
    end
    cleanupObj = onCleanup(@reset_progress_bar);

    % Ensure that the variable RandomSeed exists
    if ~ismember("RandomSeed", data_tbl.Properties.VariableNames)
        data_tbl.RandomSeed = zeros(height(data_tbl), 1);
    end

    data_tbl.Cz_adj = cell(height(data_tbl), 1);
    textprogressbar(sprintf('%36s', 'Adjusting predictions: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch options.window_type
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                z = data_tbl.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                z = data_tbl.WindowSize == w;
            case "None"
                z = true(height(data_tbl), 1);
        end

        data_tbl.Cz_adj(z) = colvec(adjust_all_predictions(data_tbl(z, :), metadata, ...
          cvscheme = options.cvscheme, ...
          scale_singular_vectors = options.scale_singular_vectors));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));


    %% Add test-set filter to each row ----
    % To determine the test-set, row-filters and cvblocks are required.
    % These are the same across all windows, so we can load a single metadata
    % file and use it to obtain all testsets.
    % We will recycle the metadata loaded above.
    data_tbl.testset = cell(height(data_tbl), 1);
    textprogressbar(sprintf('%36s', 'Add test-set filter to each row: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch options.window_type
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                z = data_tbl.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                z = data_tbl.WindowSize == w;
            case "None"
                z = true(height(data_tbl), 1);
        end

        data_tbl.testset(z) = colvec(get_all_testsets(data_tbl(z, :), metadata, ...
            cvscheme = options.cvscheme));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));


    %% Combine test-set predictions ----
    % Following the previous step where the test-set filters were added to each row
    % of the results, the metadata structure is not needed.
    data_tbl = combine_all_testset_predictions(data_tbl, "Cz_adj");


    %% **CONDITIONAL** Average predicted embeddings ----
    if options.average_predicted_embeddings
      [data_tbl, meta_tbl] = average_embeddings(data_tbl, meta_tbl, options.bootstrap_averaged_embeddings); % not implemented
    end


    %% Add the filtered target embedding to each row ----
    data_tbl.C = cell(height(data_tbl), 1);
    textprogressbar(sprintf('%36s', 'Add filtered target to each row: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch options.window_type
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                z = data_tbl.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                z = data_tbl.WindowSize == w;
            case "None"
                z = true(height(data_tbl), 1);
        end

        data_tbl.C(z) = colvec(get_all_embeddings(data_tbl(z, :), metadata, ...
          options.scale_singular_vectors));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
end


function reset_progress_bar()
    clear textprogressbar
end
