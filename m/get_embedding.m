function embedding = get_embedding(metadata, subject, opts)

    arguments
        metadata (:,:) struct
        subject (1,1) double {mustBeInteger, mustBePositive}
        opts.target_label (1,1) string {mustBeTextScalar} = "semantic"
        opts.target_type (1,1) string {mustBeTextScalar} = "similarity"
        opts.sim_source (1,1) string {mustBeTextScalar} = "Dilkina_Normalized"
        opts.sim_metric (1,1) string {mustBeTextScalar} = "cosine"
        opts.filters (1,:) string = string.empty
        opts.filters_be (1,:) string = string.empty
        opts.scale_singular_vectors (1,1) logical = true
    end

    m = select_by_field(metadata, struct('subject', subject));
    t = select_by_field(m.targets, struct( ...
                        'label', opts.target_label, ...
                        'type', "similarity", ...
                        'sim_source', regexprep(opts.sim_source, '_Dim[1-9]+', ''), ...
                        'sim_metric', opts.sim_metric));

    if isempty(opts.filters_be)
        z0 = true(m.nrow, 1);
    else
        z0 = get_row_filter(m.filters, opts.filters_be);
    end

    [svecs, svals] = embed_similarity_matrix(t.target(z0, z0), 3);
    if opts.scale_singular_vectors
        embedding = rescale_embedding(svecs, svals);
    else
        embedding = svecs;
    end

    if isempty(opts.filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, opts.filters);
    end

    embedding = embedding(z1, :);
end
