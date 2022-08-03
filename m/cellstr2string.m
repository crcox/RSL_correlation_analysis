function s = cellstr2string(x)
    try
        s = string(x);
    catch
        tmp = cellfun(@(y) rowvec(string(y)), x, 'UniformOutput', false);
        s = cat(1, tmp{:});
    end
end
