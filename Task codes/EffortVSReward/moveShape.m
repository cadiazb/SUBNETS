function [Params, b5] = moveShape(Params, b5, shapeName,endPositions, initOffSets, finalOffSets)
% Use this function to animate the translation of a shape on the screen.
% shapeName = the exact same name as the 'b5' field
% finalPosition = [x_pos y_pos] in absolute scale;

if ~exist('shapeName', 'var') || isempty(shapeName)
    warning('shapeName is required. No changes implemented')
    return
end
if ~exist('endPositions', 'var') || isempty(endPositions)
    warning('endPositions is required. No changes implemented')
    return
end
if ~exist('initOffSets','var') || isempty(initOffSets)
    initOffSets = zeros(numel(shapeName), 2);
end
if ~exist('finalOffSets','var') || isempty(finalOffSets)
    finalOffSets = zeros(numel(shapeName), 2);
end

dStep = 0.5; % Step [mm]

for ii = 1:numel(shapeName)
    initPosition = b5.([shapeName{ii} '_pos']) - initOffSets(ii,:);
    finalPosition = endPositions(ii, :);
    posPath_a = (finalPosition(2) - initPosition(2))/(finalPosition(1) - initPosition(1))^2;
    shapes.(shapeName{ii}).posPath = linspace(initPosition(1),finalPosition(1), ...
        sqrt(sum((initPosition - finalPosition).^2)) / dStep) ;
    shapes.(shapeName{ii}).posPath(2,:) = posPath_a * (shapes.(shapeName{ii}).posPath(1,:) - initPosition(1)).^2 + initPosition(2);
end

for ii = 1:numel(shapeName)
    shapes.(shapeName{ii}).posPath(1,:) = shapes.(shapeName{ii}).posPath(1,:) + linspace(initOffSets(ii,1),finalOffSets(ii,1), size(shapes.(shapeName{ii}).posPath,2)); 
    shapes.(shapeName{ii}).posPath(2,:) = shapes.(shapeName{ii}).posPath(2,:) + linspace(initOffSets(ii,2),finalOffSets(ii,2), size(shapes.(shapeName{ii}).posPath,2));
end

iPath = 1;

% Animation
vel = 400; % [mm/sec]
tStep = dStep/ vel;

b5 = bmi5_mmap(b5);
tPrevStep = b5.time_o;
while iPath <= size(shapes.(shapeName{ii}).posPath,2)
    b5 = bmi5_mmap(b5);
    if (b5.time_o - tPrevStep) >= tStep
        for ii = 1:numel(shapeName)
            b5.([shapeName{ii} '_pos']) = shapes.(shapeName{ii}).posPath(:,iPath);
        end
        tPrevStep = b5.time_o;
        iPath = iPath + 1;
    end
end
b5 = bmi5_mmap(b5);
end