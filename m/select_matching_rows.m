%SELECT_MATCHING_ROWS Return rows that contain specified values
%
% The first input is a table with multiple fields. The second input is a table
% with one row (or one row extracted from a larger table). The fields in the
% second input must be a subset of those in the first.
%
% INPUTS
%    tbl   A table to select rows from
%    match A table with one row and a subset of fields from tbl.
%
% OUTPUTS
%    A table consisting of the rows in tbl where the values match those
%    provided in match.
%
%    z is the logical vector that is applied to the rows of tbl to obtain the
%    subset.
%
%    g contains the location in "match" for each row of "tbl". This can be used
%    as group label for using with rowfun.
%
% EXAMPLES
%    a = table([1; 1; 1; 2], [1; 2; 2; 3], [10; 11; 12; 13], ...
%              'VariableNames', {'cow', 'duck', 'pig'});
%    b = table(1, 2, 'VariableNames', {'cow', 'duck'});
%    select_matching_rows(a, b)
function [tbl_subset, g, z] = select_matching_rows(tbl, match)
    fields = match.Properties.VariableNames;
    [z, g] = ismember(tbl(:, fields), match);
    tbl_subset = tbl(z, :);
end
