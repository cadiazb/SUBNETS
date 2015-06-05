function b5 = b5ObjectsOff(b5)

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

b5Fields = fieldnames(b5);

for ii = 1:numel(b5Fields)
    if strcmp(b5Fields{ii}(end-4:end), '_draw')
        if strcmp(b5Fields{ii},'SolenoidOpen_draw')
            continue
        end
        b5.(b5Fields{ii}) = DRAW_NONE;
    end
end
end