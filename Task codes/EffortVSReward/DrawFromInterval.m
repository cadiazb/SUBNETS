function x = DrawFromInterval(v)
    if isempty(v)
      error('range vector is empty');
    end

    if min(size(v)) < 1 || max(size(v)) > 2
      error('argument must be an array (1x2 or 2x1)');
    end
    
    x = v(1) + rand*(v(2)-v(1));

    % xxx someday it may be handy to draw
    % from a matrix of range vectors.

end