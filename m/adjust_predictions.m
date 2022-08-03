function Cz_adj = adjust_predictions( ...
        metadata, cvscheme, Cz, subject, cvholdout, ...
        target_label, target_type, sim_source, sim_metric, ...
        filters, filters_be, normalize_target, normalize_wrt, ...
        scale_singular_vectors)

    embedding = get_embedding(metadata, subject, target_label, target_type, ...
        sim_source, sim_metric, filters, filters_be, scale_singular_vectors);

    cvblocks = get_cvblocks(metadata, cvscheme, subject, filters);

    switch normalize_wrt
        case 'training_set'
            z2 = cvblocks ~= cvholdout;
        case 'all_items'
            z2 = true(size(embedding, 1), 1);
    end

    switch normalize_target
        case 'zscore'
            mm = mean(embedding(z2, :));
            ss = std(embedding(z2, :));

        case 'center'
            mm = mean(embedding(z2, :));
            ss = ones(size(mm));
    end

    Cz_adj = undo_normalization(Cz, mm, ss);
end

