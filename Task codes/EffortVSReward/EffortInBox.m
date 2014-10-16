function in = EffortInBox(pos, startpos, boxpos, boxscale)

if startpos(2) > boxpos(2)
    in = pos(2,:) < boxpos(2) + boxscale(2)/2;
else
    in = pos(2,:) > boxpos(2) - boxscale(2)/2;
end