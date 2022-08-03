function p = cartesian_product(varargin);
    if nargin == 1
        p = varargin{1};
    else
        c = cell(1, nargin);
        [c{:}] = ndgrid(varargin{:});
        p = cell2mat(cellfun(@colvec, c, 'UniformOutput', false));
    end
end

function c = colvec(x)
    c = x(:);
end
