function testset = get_testset(metadata, subject, options)

    arguments
      metadata
      subject
      options.cvscheme
      options.cvholdout
      options.filters
    end

    m = select_by_field(metadata, struct('subject', subject));

    if isempty(options.filters)
        z1 = true(m.nrow, 1);
    else
        z1 = get_row_filter(m.filters, options.filters);
    end

    testset = m.cvind(z1, options.cvscheme) == options.cvholdout;
end
