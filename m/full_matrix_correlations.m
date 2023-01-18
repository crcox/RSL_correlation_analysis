function x = full_matrix_correlations(data_tbl, meta_tbl, window_type, full_rank_target, subset)
    % FULL_MATRIX_CORRELATIONS Correlate S(:) and Sz(:)
    %
    % In the following, `a` and `b` are logical vectors for selecting items
    % belonging to categories a and b, respectively.
    %
    % The `full_mat` correlation analysis involves:
    %
    %     Sa = S(a, a); Sb = S(b, b);
    %     Sza = Sz(a, a); Szb = Sz(b, b);
    %     fullmat_all = corr(S(:), Sz(:));
    %     fullmat_a = corr(Sa(:), Saz(:));
    %     fullmat_b = corr(Sb(:), Sbz(:));
    %

    arguments
        data_tbl table
        meta_tbl table
        window_type string
        full_rank_target logical = false
        subset string = string({})
    end

    cleanupObj = onCleanup(@reset_progress_bar);
    x = zeros(height(data_tbl), 1);
    textprogressbar(sprintf('%36s', 'Full matrix correlations: '));
    tic;
    textprogressbar(0);
    for i = 1:height(meta_tbl)
        metadata = meta_tbl.metadata(i, :);
        switch window_type
            case "MovingWindow"
                w = meta_tbl.WindowStart(i);
                z = data_tbl.WindowStart == w;
            case "OpeningWindow"
                w = meta_tbl.WindowSize(i);
                z = data_tbl.WindowSize == w;
            case "None"
                z = true(height(data_tbl), 1);
        end

        x(z) = cell2mat(do_all_fullmat_corr_subset(metadata, full_rank_target, data_tbl(z, :), subset));
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
end


function reset_progress_bar()
    clear textprogressbar
end
