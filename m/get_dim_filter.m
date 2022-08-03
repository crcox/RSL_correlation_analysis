function z = get_dim_filter(filters, labels, dimension)
    match = struct('label', cellstr(labels), 'dimension', dimension);
    f = select_by_field(filters(:), match);
    z = all(cell2mat(cellfun(@colvec, {f.filter}, 'UniformOutput', false)), 2);
end

