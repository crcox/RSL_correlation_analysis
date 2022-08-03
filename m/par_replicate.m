function y = replicate(nrep, fun)
    y = cell(nrep, 1);
    parfor i = 1:nrep
        y{i} = feval(fun);
    end
end
