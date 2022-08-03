function tbl = expand_cellvec2table(C, VariableNames)
    tmp = cell(numel(C), 1);
    n = cellfun(@(x) 1:size(x, 1), C, 'UniformOutput', false);
    [tmp{:}] = ndgrid(n{:});
    for i = 1:numel(C)
        ix = tmp{i}(:);
        tmp{i} = C{i}(ix, :);
    end
    s = cell2struct(tmp, VariableNames, 1);
    tbl = struct2table(s);
end
