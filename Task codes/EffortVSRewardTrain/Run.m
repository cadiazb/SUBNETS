function Run(SubjectID)

if (nargin<1),
    fprintf('\nERROR: Missing Input Parameters! \n')
    fprintf('You must specify the following:\n')
    fprintf('> SubjectID\n\n');
    return
end

Params.SubjectID = SubjectID;

ExperimentStart;

[Params, b5] = TaskParams(Params);

TaskLoop(Params, b5);

end