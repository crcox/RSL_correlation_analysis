%SELECT_BY_FIELD Subset a structured array with field-value pairs
%
% Return array elements where specified fields equal specified values.
%
% INPUTS
%    s        A structured array
%    varargin A set of field-value pairs. In each pair, the first element in a
%             string specifying a field to inspect and the second element is
%             the value to check for within that field.
%
% OUTPUTS
%    A subset of structures from s where the specified fields have the
%    specified values.
%
% NOTES
%    isequal('cat', "cat") == true
%
% EXAMPLES
%    s = struct('a', {1:3, 'carrot', 'carrot'}, 'b', {1, 1, 2});
%    select_by_field(s, 'a', 1:3)
%    select_by_field(s, 'b', 1)
%    select_by_field(s, 'a', 'carrot', 'b', 1)
function s_subset = select_by_field(s, match)
    if length(match) > 1
        tmp = arrayfun(@(x) select_by_field(s, x), match, ...
            'UniformOutput', false);
        tmp = tmp(~cellfun('isempty', tmp));
        s_subset = cat(2, tmp{:});
    else
        z = true(size(s));
        keys = fieldnames(match);
        for i = 1:length(keys)
            k = keys{i};
            v = match.(k);
            z = z & reshape(cellfun(@(x) isequal(x, v), {s.(k)}), size(s));
        end
        s_subset = s(z);
    end
end
