function y = sparse2dense(x, z)
    y = zeros(size(z, 1), size(x, 2));
    y(z, :) = x;
end

