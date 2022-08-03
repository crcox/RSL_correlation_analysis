function tbl = expand2table(s)
    x = structfun(@(y) sort(unique(y)), s, 'UniformOutput', false);
    n = structfun(@(y) 1:length(y), x, 'UniformOutput', false);
    nc = struct2cell(n);
    idx = cartesian_product(nc{:});
    fields = fieldnames(x);
    for i = 1:length(fields)
        field = fields{i};
        x.(field) = colvec(x.(field)(idx(:, i)));
    end
    tbl = struct2table(x);
end

