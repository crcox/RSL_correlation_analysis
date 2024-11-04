%APPLY_NORMALIZATION Scale and translate matrix columns
%
%
% INPUTS
%    x A matrix
%    translate A vector with as many elements as columns in x.
%    scale A vector with as many elements as columns in x.
%
% OUTPUTS
%    A matrix with the same dimensions as x. Each column will have been scaled
%    and translated by the given parameters.
%
% EXAMPLES
% m = rnorm(1, 5);
% s = 1:5;
% x = bsxfun(@plus, bsxfun(@times, ones(10, 5), s), m);
% y = apply_normalization(x, m, s);
% z = undo_normalization(y, m, s);
%

function y = apply_normalization(x, translate, scale)
    y = bsxfun(@rdivide, bsxfun(@minus, x, translate), scale);
end


