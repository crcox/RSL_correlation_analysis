function x = itemwise_correlations(data_tbl, meta_tbl, full_rank_target, category_labels, window_type)
    arguments
        data_tbl table
        meta_tbl table
        full_rank_target logical
        category_labels string
        window_type string = "None"
    end
    x = cell(height(data_tbl), 1);
    textprogressbar(sprintf('%36s', 'Itemwise correlations: '));
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

        x(z) = do_all_itemwise_corr(metadata, full_rank_target, data_tbl(z, :), 'CategoryLabels', category_labels);
        textprogressbar((i/height(meta_tbl)) * 100);
    end
    textprogressbar(sprintf(' done (%.2f s)', toc));
end
