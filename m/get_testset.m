function testset = get_testset(metadata, cvscheme, subject, cvholdout, filters)
    m = select_by_field(metadata, struct('subject', subject));

    if isempty(filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, filters);
    end

    testset = m.cvind(z1, cvscheme) == cvholdout;
end
