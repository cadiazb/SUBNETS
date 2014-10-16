function in = EffortInBox(pos, startpos, boxpos, boxscale)

if startpos(1) > boxpos(1)
    in = pos(1,:) < boxpos(1) + boxscale(1)/2;
else
    in = pos(1,:) > boxpos(1) - boxscale(1)/2;
end