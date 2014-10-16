function PathAdder(s)
    f = fullfile(pwd,s);
    fprintf('addpath: %s\n',f);
    addpath(f);
end

%{
function Path_Adder(s)
    f = fullfile(pwd,s);
    fprintf('addpath: %s\n',f);
    addpath(f);
end

function Path_Remover(s)
    f = fullfile(pwd,s);
    fprintf('rmpath: %s\n',f);
    rmpath(f);
end
%}