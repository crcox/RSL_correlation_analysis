function [fullmat, itemwise, embedcor] = correlation_analysis(final, perm, meta_tbl, options)
    % CORRELATION_ANALYSIS Evaluate model against target structure.
    %
    % window_type category_labels, full_rank_target, average_predicted_embeddings, ...
    % bootstrap_averaged_embeddings, cvscheme, scale_singular_vectors)
    % Parameters
    % ----------
    % final : table
    %   Results from representational similarity learning (RSL).
    % perm : table
    %   Results when targets are permuted
    % meta_tbl : table
    %   Metadata structures nested in a table for easy selection. This is
    %   especially useful when many metadata files went into the analysis
    %   (e.g., when an analysis is performed within a series of moving
    %   windows).
    % window_type : string
    %    None, MovingWindow, or OpeningWindow
    % category_labels : string
    %    Defaults to empty string. Labels correspond to row-filters that can
    %    be applied to subset the data.
    % full_rank_target : logical
    %    Should full_rank and itemwise correlations be computed with respect
    %    to the full rank similarity matrix, or the low rank approximation
    %    obtained from the low rank embedding. Note that the low-rank
    %    embedding is what was actually modeled using RSL, not the full rank
    %    matrix. It makes sense for this to be false.  Ideally the
    %    difference between full- and low-rank matrices will be small.
    % average_predicted_embeddings : logical
    %    If true, the predicted values from each subject are averaged before
    %    correlating with the target structure. The default behavior (false)
    %    is to correlate each subject's predicted embedding with the true
    %    structure and then average the correlations.
    % bootstrap_averaged_embeddings : logical
    %    This only influences the analysis when
    %    `average_predicted_embeddings=true`. It toggles the procedure for
    %    averaging the predicted embeddings for permuted targets.  If false,
    %    then the embeddings are averaged across subjects once per
    %    permutation order (indicated by the RandomSeed). If true, then many
    %    group-level average embeddings are bootstrapped by randomly
    %    sampling a permutation order from each subject and averaging those
    %    (see Steltzer, Chen, and Turner, 2013, NeuroImage). This is
    %    repeated 10,000 times. This is the default behavior.
    % cvscheme : double
    %    Within the metadata structure there is a `cvind` matrix, where each
    %    column is a `cvscheme`. This is an index into the columns of that
    %    matrix. It is important that the analysis breaks up the data into
    %    training and test sets in exactly the same way as during the model
    %    fitting step. Set this to whatever it was set to during the model
    %    fitting step. Note, that the default is 1. If you used some other
    %    scheme, this default will lead to incorrect and overly-optimistic
    %    results. Be careful about this!
    % scale_singular_vectors : logical
    %    This is another parameter that should be inherited from the model
    %    fitting step. There when generating the target embedding for model
    %    fitting, each orthonormal singular vector may be optionally scaled
    %    by the singular values. This will make it so that the variance of
    %    each dimension of the embedding is proportional to it's importance
    %    to representing the original similarity matrix. Note that the
    %    default is true, but it is important that this parameter is set to
    %    whatever was done during the model fitting step! Again, be careful
    %    about this!
    %
    %
    % Returns
    % -------
    % fullmat : struct
    %     A structured array with fields `final` and `perm` containing the
    %     output of the `full_matrix` correlation analysis.
    % itemwise : struct
    %     A structured array with fields `final` and `perm` containing the
    %     output of the `itemwise` correlation analysis.
    % embedcor : struct
    %     A structured array with fields `final` and `perm` containing the
    %     output of the `embedcor` correlation analysis.
    %
    %
    % Notes
    % -----
    % The target embeddings used in the model fitting step are obtained by
    % singular value decomposition `[U,S,V]=svd(X)`, where X is the full-rank
    % similarity matrix, `S` is a matrix with singular values on the diagonal,
    % `U` is a matrix of orthonormal singular vectors, and `U=V` because X is
    % symmetric. `X` can be recovered as `X=U*S*U'`. The target embedding will
    % be the first `r` columns of `U`, optionally scaled by the sqrt of the
    % singular values, `C=U(:,1:r)*sqrt(S(1:r,1:r))`. After model fitting, the
    % predicted embedding `Cz` can be obtained, and a prediction of the full
    % similarity matrix can be obtained as well: `Sz=Cz*Cz'`.
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
    % The `itemwise` correlation analysis involves:
    %
    %     for i = 1:nitems
    %         itemwise_all(i) = corr(S(:, i), Sz(:, i));
    %         if a(i)
    %             itemwise_within(i) = corr(S(a, i), Sz(a, i));
    %             itemwise_between(i) = corr(S(b, i), Sz(b, i));
    %         else
    %             itemwise_between(i) = corr(S(a, i), Sz(a, i));
    %             itemwise_within(i) = corr(S(b, i), Sz(b, i));
    %         end
    %     end
    %     itemwise_all_all = mean(itemwise_all);
    %     itemwise_all_a = mean(itemwise_all(a));
    %     itemwise_all_b = mean(itemwise_all(b));
    %     itemwise_within_all = mean(itemwise_within);
    %     itemwise_within_a = mean(itemwise_within(a));
    %     itemwise_within_b = mean(itemwise_within(b));
    %     itemwise_between_all = mean(itemwise_between);
    %     itemwise_between_a = mean(itemwise_between(a));
    %     itemwise_between_b = mean(itemwise_between(b));
    %
    % The `embedcor` correlation analysis involves:
    %
    %     for j = 1:r
    %         embedcor_all = corr(C(:, j), C(:, j));
    %         embedcor_a = corr(C(a, j), C(a, j));
    %         embedcor_b = corr(C(b, j), C(b, j));
    %     end
    %
    %
    % Examples
    % --------
    %     % Create meta_tbl
    %     meta_vars = ["BaselineWindow", "BoxCar", "WindowStart", "WindowSize", ...
    %             "metadata", "metadata_varname"];
    %     meta_tbl = unique(final(:, meta_vars));
    %     metacell = cell(height(meta_tbl), 1);
    %     for i = 1:height(meta_tbl) %#ok
    %         args = table2cell(meta_tbl(i, meta_vars));
    %         metacell{i} = load_metadata(analysis, args{:});
    %     end
    %     meta_tbl.metadata = cat(1, metacell{:});
    %

    % CHANGES
    % =======
    % 2022 DEC  26
    % * Refactored to make script more readable and modular.
    % * Output structures/tables are segregaged by anaysis type.
    % --> Previously, variables from different analyses were acccumulating into
    %     a table at the end that had everything. It was confusing.
    %
    % 2022 JULY 14
    % * Implemented a conditional to average over predicted embeddings rather
    %   than averaging over correlations between predicted and true embeddings.
    %   Not relevant to "Opening Window ECoG" paper.
    %

    arguments
        final table
        perm table
        meta_tbl table
        options.window_type (1,1) string {mustBeMember(options.window_type, ["OpeningWindow", "MovingWindow", "None"])} = "None";
        options.category_labels string = string({});
        options.full_rank_target logical = false
        options.average_predicted_embeddings logical = false
        options.bootstrap_averaged_embeddings logical = true
        options.cvscheme double = 1
        options.scale_singular_vectors logical = true
    end
    cleanupObj = onCleanup(@reset_progress_bar);
    full_timer = tic();

    window_type = options.window_type;
    category_labels = options.category_labels;
    full_rank_target = options.full_rank_target;
    average_predicted_embeddings = options.average_predicted_embeddings;
    bootstrap_averaged_embeddings = options.bootstrap_averaged_embeddings;
    cvscheme = options.cvscheme;
    scale_singular_vectors = options.scale_singular_vectors;

    %% Prepare data for analyses ----
    % 1. Adjust predictions (undo normalization)
    % 2. Add test-set filter to each row
    % 3. Combine test-set predictions
    % 4. **CONDITIONAL** Average predicted embeddings (N.B., this create an
    %    "avg" subject in `meta_tbl`; otherwise `meta_tbl` is unchanged.
    % 5. Add the filtered target embedding to each row
    fprintf("\nPREP DATA TABLES\n");
    fprintf("================\n");
    fprintf("1) Results\n")
    fprintf("----------\n")
    [final, meta_tbl] = prepare_data_table(final, meta_tbl, window_type, average_predicted_embeddings, bootstrap_averaged_embeddings, cvscheme, scale_singular_vectors);
    fprintf("\n2) Permutations\n")
    fprintf("---------------\n")
    [perm, meta_tbl] = prepare_data_table(perm, meta_tbl, window_type, average_predicted_embeddings, bootstrap_averaged_embeddings, cvscheme, scale_singular_vectors);


    %% Prepare output structures ----
    % N.B. prep_output_structs() is defined locally; see end of file.
    [fullmat, embedcor, itemwise] = prep_output_structs(window_type, average_predicted_embeddings);


    %% Compute full-matrix correlations ----
    fprintf("\nFull-matrix correlations\n");
    fprintf("========================\n");
    fprintf("1) Results\n")
    fprintf("----------\n")
    fullmat(1).final = final;
    fullmat(1).final.fullcor_all = full_matrix_correlations(final, meta_tbl, window_type, full_rank_target);
    for i = 1:length(category_labels)
        c = category_labels{i};
        f = sprintf('fullcor_%s', c);
        fullmat(1).final.(f) = full_matrix_correlations(final, meta_tbl, window_type, full_rank_target, c);
    end

    fprintf("\n2) Permutations\n")
    fprintf("---------------\n")
    fullmat(1).perm = perm;
    fullmat(1).perm.fullcor_all = full_matrix_correlations(perm, meta_tbl, window_type, full_rank_target);
    for i = 1:length(category_labels)
        c = category_labels{i};
        f = sprintf('fullcor_%s', c);
        fullmat(1).perm.(f) = full_matrix_correlations(perm, meta_tbl, window_type, full_rank_target, c);
    end

    % Average correlations over subjects (if embeddings were not averaged)
    if ~average_predicted_embeddings
        vars = "fullcor_" + ["all", category_labels];
        fullmat(2).final = average_over_subjects(fullmat(1).final, vars);
        fullmat(2).perm = average_over_subjects_bs(fullmat(1).perm, vars, 10000);
    end


    %% Compute itemwise correlations between true and predicted sim matrices ----
    fprintf("\nItemwise correlations\n");
    fprintf("=====================\n");
    fprintf("1) Results\n")
    fprintf("----------\n")
    itemwise(1).final = final;
    itemwise(1).final.itemwise = itemwise_correlations(final, meta_tbl, full_rank_target, category_labels, window_type);
    fprintf("\n2) Permutations\n")
    fprintf("---------------\n")
    itemwise(1).perm = perm;
    itemwise(1).perm.itemwise = itemwise_correlations(perm,  meta_tbl, full_rank_target, category_labels, window_type);

    % Average over items
    fprintf('Compute means over items ');
    tic;
    itemwise(2).final = [removevars(itemwise(1).final, "itemwise"), get_itemwise_corr_means(itemwise(1).final.itemwise)];
    itemwise(2).perm = [removevars(itemwise(1).perm, "itemwise"), get_itemwise_corr_means(itemwise(1).perm.itemwise)];
    fprintf('(%.2f s)\n', toc);

    % Average correlations over subjects (if embeddings were not averaged)
    if ~average_predicted_embeddings
        fprintf('Compute means over subjects ');
        tic;
        vars = ["itemcor_all_" + ["all", category_labels], "itemcor_within_" + ["all", category_labels], "itemcor_between_" + ["all", category_labels]];
        itemwise(3).final = average_over_subjects(itemwise(2).final, vars);
        itemwise(3).perm = average_over_subjects_bs(itemwise(2).perm, vars, 10000);
        fprintf('(%.2f s)\n', toc);
    end


    %% Compute correlations between true and predicted embeddings by dimension ----
    fprintf("\nEmbedding correlations\n");
    fprintf("======================\n");
    fprintf("1) Results\n")
    fprintf("----------\n")
    embedcor(1).final = final;
    embedcor(1).final.embedcor_all = embedding_correlations(final, meta_tbl, window_type);
    for i = 1:length(category_labels)
        c = category_labels{i};
        f = sprintf('embedcor_%s', c);
        embedcor(1).final.(f) = embedding_correlations(final, meta_tbl, window_type, c);
    end

    fprintf("\n2) Permutations\n")
    fprintf("---------------\n")
    embedcor(1).perm = perm;
    embedcor(1).perm.embedcor_all = embedding_correlations(perm, meta_tbl, window_type);
    for i = 1:length(category_labels)
        c = category_labels{i};
        f = sprintf('embedcor_%s', c);
        embedcor(1).perm.(f) = embedding_correlations(perm, meta_tbl, window_type, c);
    end

    % Average correlations over subjects (if embeddings were not averaged)
    if ~average_predicted_embeddings
        vars = "embedcor_" + ["all", category_labels];
        embedcor(2).final = average_over_subjects(embedcor(1).final, vars);
        embedcor(2).perm = average_over_subjects_bs(embedcor(1).perm, vars, 10000);
    end


    fprintf('---------------------\n');
    fprintf('TOTAL ELAPSED: %.2f s\n', toc(full_timer));

end

function reset_progress_bar()
    clear textprogressbar
end

function res = tern(cond, resTrue, resFalse)
    if cond
        res = resTrue;
    else
        res = resFalse;
    end
end

function [fullmat, embedcor, itemwise] = prep_output_structs(window_type, average_predicted_embeddings)
    if average_predicted_embeddings
        fullmat = struct(...
          'label', {"avg_embed"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

        embedcor = struct(...
          'label', {"avg_embed"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

        itemwise = struct(...
          'label', {"avg_embed_items", "avg_embed"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

    else
        fullmat = struct(...
          'label', {"subjects", "avg"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

        embedcor = struct(...
          'label', {"subjects", "avg"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

        itemwise = struct(...
          'label', {"items", "subjects", "avg"}, ...
          'window_type', window_type, ...
          'avg_predicted_embeddings', average_predicted_embeddings, ...
          'final', [], ...
          'perm',  [] ...
        );

    end
end

