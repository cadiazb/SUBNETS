function x = DrawFromProbVec(v)
    if isempty(v)
        x = 1;
        return;
    end

    if sum(v) ~= 1
        error('probabilities must add up to 1');
    end

    p = cumsum(v);
    x = find(rand(1)<=p,1);
end