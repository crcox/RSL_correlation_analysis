function y = normalize_by_subset(x, z)
    m = mean(x(z, :));
    s = std(x(z, :));
    y = apply_normalization(x, m ,s);
end
