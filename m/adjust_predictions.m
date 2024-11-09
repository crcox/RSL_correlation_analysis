function Cz_adj = adjust_predictions(Cz, metadata, subject, options)

    arguments
        Cz (:,:) double
        metadata (:,:) struct
        subject (1,1) double {mustBeInteger, mustBePositive}
        options.cvscheme (1,1) double {mustBeInteger, mustBePositive}
        options.cvholdout (1,1) double {mustBeInteger, mustBePositive}
        options.target_label (1,1) string {mustBeTextScalar}
        options.target_type (1,1) string {mustBeMember(options.target_type, ["embedding", "similarity"])}
        options.sim_source (1,1) string {mustBeTextScalar} = "Dilkina_Normalized"
        options.sim_metric (1,1) string {mustBeTextScalar} = "cosine"
        options.filters (1,:) string = string.empty
        options.filters_be (1,:) string = string.empty
        options.normalize_target (1,1) string {mustBeMember(options.normalize_target, ["none", "center", "zscore"])}
        options.normalize_wrt(1,1) string {mustBeMember(options.normalize_wrt, ["all_items", "training_set"])}
        options.scale_singular_vectors (1,1) logical
    end

    embedding = get_embedding(metadata, subject, ...
        target_label = options.target_label, ...
        target_type = options.target_type, ...
        sim_source = options.sim_source, ...
        sim_metric = options.sim_metric, ...
        filters = options.filters, ...
        filters_be = options.filters_be, ...
        scale_singular_vectors = options.scale_singular_vectors);

    cvblocks = get_cvblocks(metadata, subject, ...
        cvscheme = options.cvscheme, ...
        filters = options.filters);

    switch lower(options.normalize_wrt)
        case 'training_set'
            z2 = cvblocks ~= options.cvholdout;
        case 'all_items'
            z2 = true(size(embedding, 1), 1);
    end

    switch lower(options.normalize_target)
        case 'zscore'
            mm = mean(embedding(z2, :));
            ss = std(embedding(z2, :));

        case 'center'
            mm = mean(embedding(z2, :));
            ss = ones(size(mm));
    end

    Cz_adj = undo_normalization(Cz, mm, ss);
end

