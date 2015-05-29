function [objHandles] = getHandles(guiHandle)
% Get all UI object handles from a GUI figure
% [objHandles] = getHandles(guiHandle)

ch = get(guiHandle,'Children');
objHandles=[];
if ~isempty(ch)
    for jj = 1:length(ch)
        t=get(ch(jj), 'Tag');
        objHandles.(get(ch(jj), 'Tag')) = ch(jj);
    end
    
    for jj = 1: length(ch)
        handlesChildren = getHandles(ch(jj));
        
        if ~isempty(handlesChildren)
            fieldNames1 = fieldnames(objHandles);
            fieldNames2 = fieldnames(handlesChildren);
            fieldNames = [fieldNames1; fieldNames2];
            
            c1 = struct2cell(objHandles);
            c2 = struct2cell(handlesChildren);
            c=[c1;c2];
            
            objHandles = cell2struct(c,fieldNames,1);
        end
    end
end
end
