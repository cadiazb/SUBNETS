function Run(SubjectID, taskType, maxForce)

if (nargin<1),
    fprintf('\nERROR: Missing Input Parameters! \n')
    fprintf('You must specify the following:\n')
    fprintf('> SubjectID\n\n');
    return
end

Params.SubjectID = SubjectID;

ExperimentStart;

if exist('taskType', 'var') && ~isempty(taskType) ...
        && exist('maxForce', 'var') && ~isempty(maxForce)
    
    [Params, b5] = TaskParams(Params, taskType, maxForce);
else
    [Params, b5] = TaskParams(Params,[],[]);
end

TaskLoop(Params, b5);

end