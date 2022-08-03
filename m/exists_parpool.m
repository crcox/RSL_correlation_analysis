function b = exists_parpool()
    b = false;
    if license('test', 'distrib_computing_toolbox');
        b = ~isempty(gcp('nocreate'));
    end
end
