function in = EffortInBox(pos, startpos, boxpos)

if startpos(2) > boxpos(2)
    in = pos(2,:) < boxpos(2);
else
    in = pos(2,:) > boxpos(2);
end