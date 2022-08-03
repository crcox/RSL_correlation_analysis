function corr3D = do_corr3D(metadata, subject, C, Cz, varargin)
    p = inputParser();
    addRequired(p, "metadata", @isstruct);
    addRequired(p, "subject");
    addRequired(p, "C", @isnumeric);
    addRequired(p, "Cz", @isnumeric);
    addOptional(p, 'filters', [], @(x) isstring(x) || isempty(x));
    addOptional(p, 'subset', [], @(x) isstring(x) || isempty(x));
    parse(p, metadata, subject, C, Cz, varargin{:});

    filters = p.Results.filters;
    subset = p.Results.subset;

    m = select_by_field(metadata, struct('subject', subject));

    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end

    if isempty(subset)
        z2 = true(m.nrow, 1);
    else
        z2 = get_row_filter(m.filters, subset);
    end

    corr3D = nrsa_corr3D(C(z2(z1), :), Cz(z2(z1), :));
end

