function cvblocks = get_cvblocks(metadata, subject, options)
    arguments
        metadata struct
        subject (1,1) double {mustBeInteger}
        options.cvscheme (1,1) double {mustBeInteger} = 1
        options.filters (1,:) string = string.empty
    end
    m = select_by_field(metadata, struct('subject', subject));

    if isempty(options.filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, options.filters);
    end

    cvblocks = m.cvind(z1, options.cvscheme);
end
