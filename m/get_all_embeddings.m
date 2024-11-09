function embeddings = get_all_embeddings(metadata, results, scale_singular_vectors)
    vars = ["subject", "target_label", "target_type", "sim_source", "sim_metric", ...
        "filters", "FiltersToApplyBeforeEmbedding"];
    func = @(s,tl,tt,ss,sm,f,fb) get_embedding(metadata, s, ...
      target_label = tl, ...
      target_type = tt, ...
      sim_source = ss, ...
      sim_metric = sm, ...
      filters = f, ...
      filters_be = fb, ...
      scale_singular_vectors = scale_singular_vectors);
    if exists_parpool()
        embeddings = par_rowfun(func, results, ...
                                'InputVariables', vars, ...
                                'ExtractCellContents', true, ...
                                'OutputFormat', "cell");
    else
        embeddings = rowfun(func, results, ...
                            'InputVariables', vars, ...
                            'ExtractCellContents', true, ...
                            'OutputFormat', "cell");
    end
end

