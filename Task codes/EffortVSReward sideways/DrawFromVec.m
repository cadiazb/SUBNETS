function x = DrawFromVec(v)
    if isempty(v)
      error('vector is empty');
    end

    if min(size(v)) < 1
      error('argument must be array (1xn or nx1)');
    end
    
    % Generate integers, uniformly from the interval [1, n].
    n = length(v);
    r = floor(1 + n.*rand(1,1));
    
    if isnumeric(v)
      x = v(r);
    elseif iscell(v)
      x = v{r};
    elseif isstruct(v)
      x = v(r);
    else
      error('i dont know what to do with this datatype');
    end
end