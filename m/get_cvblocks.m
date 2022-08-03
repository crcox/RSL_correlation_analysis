function cvblocks = get_cvblocks(metadata, cvscheme, subject, filters)
    m = select_by_field(metadata, struct('subject', subject));

    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end

    cvblocks = m.cvind(z1, cvscheme);
end
