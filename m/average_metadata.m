function m_avg = average_metadata(metadata)
    metadata_sorted = metadata;
    for i = 1:length(metadata)
        m = metadata(i);

        %% Sort each subject's data into alphabetical stimulus order
        [m.stimuli, ix] = sort(m.stimuli);
        for j = 1:length(m.targets)
            switch m.targets(j).type
            case 'category'
                m.targets(j).target = m.targets(j).target(ix);
            case 'embedding'
                m.targets(j).target = m.targets(j).target(ix, :);
            case 'similarity'
                m.targets(j).target = m.targets(j).target(ix, ix);
            end
        end
        for j = 1:length(m.filters)
            if m.filters(j).dimension == 1
                m.filters(j).filter = m.filters(j).filter(ix);
            end
        end
        m.cvind = m.cvind(ix, :);
        metadata_sorted(i) = m;
    end
    m_avg = metadata(1);
    % After sorting, targets will be the same across subjects. We can take
    % targets from the first sorted subject
    for j = 1:length(m_avg.targets)
        m_avg.targets(j).target = metadata_sorted(1).targets(j).target;
    end
    % After sorting, filters may still differ across subjects.
    for j = 1:length(m_avg.filters)
        if m_avg.filters(j).dimension == 1
            tmp = arrayfun(@(x) rowvec(x.filters(j).filter), metadata_sorted, 'UniformOutput', false);
            m_avg.filters(j).filter = any(cat(1, tmp{:}), 1);
        else
            m_avg.filters(j).filter = [];
        end
    end
    % After sorting, cvind will be the same across subjects. We can take
    % cvind from the first sorted subject
    m_avg.cvind = metadata_sorted(1).cvind;
    m_avg.subject = 'avg';
    m_avg.samplingrate = [];
end