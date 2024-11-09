function embedding = get_embedding(metadata, subject, options)

    arguments
        metadata (:,:) struct
        subject (1,1) double {mustBeInteger, mustBePositive}
        options.target_label (1,1) string {mustBeTextScalar} = "semantic"
        options.target_type (1,1) string {mustBeTextScalar} = "similarity"
        options.sim_source (1,1) string {mustBeTextScalar} = "Dilkina_Normalized"
        options.sim_metric (1,1) string {mustBeTextScalar} = "cosine"
        options.filters (1,:) string = string.empty
        options.filters_be (1,:) string = string.empty
        options.scale_singular_vectors (1,1) logical = true
    end

    m = select_by_field(metadata, struct('subject', subject));
    t = select_by_field(m.targets, struct( ...
                        'label', options.target_label, ...
                        'type', "similarity", ...
                        'sim_source', regexprep(options.sim_source, '_Dim[1-9]+', ''), ...
                        'sim_metric', options.sim_metric));

    if isempty(options.filters_be)
        z0 = true(m.nrow, 1);
    else
        z0 = get_row_filter(m.filters, options.filters_be);
    end

    if isempty(options.filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, options.filters);
    end

    switch options.target_type
        case "embedding"
            embedding = t.target;

        case "similarity"
            if isempty(options.filters_be)
                z0 = true(m.nrow, 1);
            else
                z0 = get_row_filter(m.filters, options.filters_be);
            end

            [svecs, svals] = embed_similarity_matrix(t.target(z0, z0), 3);
            if options.scale_singular_vectors
                embedding = rescale_embedding(svecs, svals);
            else
                embedding = svecs;
            end
    end

    embedding = embedding(z1, :);
end
