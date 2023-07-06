function embedding = get_embedding(metadata, subject, target_label, target_type, ...
        sim_source, sim_metric, filters, filters_be,  scale_singular_vectors)
    m = select_by_field(metadata, struct('subject', subject));
    t = select_by_field(m.targets, struct( ...
                        'label', target_label, ...
                        'type', target_type, ...
                        'sim_source', regexprep(sim_source, '_Dim[1-9]+', ''), ...
                        'sim_metric', sim_metric));
    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end
                  
    switch target_type
        case "embedding"
            embedding = t.target;
            
        case "similarity"
            if isempty(filters_be)
                z0 = true(m.nrow, 1);
            else
                z0 = get_row_filter(m.filters, filters_be);
            end
            
            [svecs, svals] = embed_similarity_matrix(t.target(z0, z0), 3);
            if scale_singular_vectors
                embedding = rescale_embedding(svecs, svals);
            else
                embedding = svecs;
            end
    end

    embedding = embedding(z1, :);
end
