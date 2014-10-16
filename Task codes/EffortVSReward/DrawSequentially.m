% Draw from vector-v at index-k
% Returns: x = v[k]
% (on overflow, wrap to the beginning)
function x = DrawSequentially(v,k)
    if isempty(v)
        error('empty sequence vector');
    end
    
    if k < 1
        error('illegal sequence vector index');
    end

    i = mod(k-1,length(v)) + 1;
    
    x = v(i);
end