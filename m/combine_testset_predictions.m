function Cz_test = combine_testset_predictions(Cz, testset)
    Cz_test = nan(size(Cz{1}));
    for i = 1:numel(Cz)
        Cz_test(testset{i}, :) = Cz{i}(testset{i}, :);
    end
end

