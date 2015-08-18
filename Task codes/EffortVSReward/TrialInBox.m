function in = TrialInBox(pos,rad,boxpos,win)

if (length(win) == 1),
    in = sqrt( (pos(1,:)-boxpos(1)).^2 + (pos(2,:)-boxpos(2)).^2 ) < win + rad;
else
    in = abs(pos(1,:)-boxpos(1)) <= (win(1)+rad(1)) & abs(pos(2,:)-boxpos(2)) <= (win(2)+rad(2));
end


