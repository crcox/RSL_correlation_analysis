function x = embedding_correlations(data_tbl, meta_tbl, window_type, subset)
    arguments
        data_tbl table
        meta_tbl table
        window_type string = "None"
        subset string = string({})
    end

    r = size(data_tbl.C{1}, 2);
    x = zeros(height(data_tbl), r);
    textprogressbar(sprintf('%36s', 'Correlations by dimension: '));
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

        x(z, 1:r) = cell2mat(do_all_corr3D(metadata, data_tbl(z, :), subset));

        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
end
