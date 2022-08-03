function y = replicate(nrep, fun)
    y = cell(nrep, 1);
    for i = 1:nrep
        y{i} = fun();
    end
end
