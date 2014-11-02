function b5 = CoinLookUp(coinValues, b5)
% Look up table for graphics of the coins to cue reward.
% table{5} = ...
%               {coinValue, ON/OFF, scale, pos, color};
% American coins
%           Diameter    Color       Value
% Quarter:  24.26mm     Silver      25cents
% Dime:     17.91       Silver      10
% Nickel:   21.21       Silver      5
% Penny:    19.05       Copper      1

DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

try
    load('CoinLookUpTable.mat');
catch
    maxNumberofCoins    = 6; %Max number of coins to be shown at each level
    coinScaleFactor     = 20/25;
    xPosScaleFactor     = 15;

    USCoins.Quarter.Diam  = 30 * coinScaleFactor;
    USCoins.Quarter.Color     = [0.7529 0.7529 0.7529 1];

    USCoins.Dime.Diam = 17 * coinScaleFactor;
    USCoins.Dime.Color     = [0.7529 0.7529 0.7529 1];

    USCoins.Nickel.Diam  = 22 * coinScaleFactor;
    USCoins.Nickel.Color     = [0.7529 0.7529 0.7529 1];

    USCoins.Penny.Diam  = 15 * coinScaleFactor;
    USCoins.Penny.Color     = [0.6784    0.4353    0.4118 1];

    USCoins.Black = [0 0 0 0];

    coinTable{1} = unique([0, 0.5, 1:25, 41]); % {1} = coinValue,
    coinTable{2} = zeros(maxNumberofCoins, numel(coinTable{1})); %{2} = ON/OFF
    coinTable{3} = zeros(maxNumberofCoins, numel(coinTable{1}));%{3} = scale
    coinTable{4} = zeros(maxNumberofCoins, 2, numel(coinTable{1}));%{4} = pos
    coinTable{5} = zeros(maxNumberofCoins, 4, numel(coinTable{1}));%{5} = color

    % I'm going to create the table here, have to manually entry
    
    % 0
    coinIndex = find(coinTable{1} == 0);

    coinTable{2}(:,coinIndex) = [0 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [0 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Black; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];
                                    
    % 0.5
    coinIndex = find(coinTable{1} == 0.5);

    coinTable{2}(:,coinIndex) = [1 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [1 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 1
    coinIndex = find(coinTable{1} == 1);

    coinTable{2}(:,coinIndex) = [1 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 2
    coinIndex = find(coinTable{1} == 2);

    coinTable{2}(:,coinIndex) = [1 1 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 3
    coinIndex = find(coinTable{1} == 3);

    coinTable{2}(:,coinIndex) = [1 1 1 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 4
    coinIndex = find(coinTable{1} == 4);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3  0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 5
    coinIndex = find(coinTable{1} == 5);

    coinTable{2}(:,coinIndex) = [1 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Nickel.Diam 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Nickel.Color; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 6
    coinIndex = find(coinTable{1} == 6);

    coinTable{2}(:,coinIndex) = [1 1 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Nickel.Diam 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1.2 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Nickel.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 7
    coinIndex = find(coinTable{1} == 7);

    coinTable{2}(:,coinIndex) = [1 1 1 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2.2 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 8
    coinIndex = find(coinTable{1} == 8);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3.2 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 9
    coinIndex = find(coinTable{1} == 9);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4.2 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color;...
                                        USCoins.Black   ];

    % 10
    coinIndex = find(coinTable{1} == 10);

    coinTable{2}(:,coinIndex) = [1 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Dime.Diam 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Dime.Color; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 11
    coinIndex = find(coinTable{1} == 11);

    coinTable{2}(:,coinIndex) = [1 1 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Dime.Diam 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 12
    coinIndex = find(coinTable{1} == 12);

    coinTable{2}(:,coinIndex) = [1 1 1 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 13
    coinIndex = find(coinTable{1} == 13);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 14
    coinIndex = find(coinTable{1} == 14);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color;...
                                        USCoins.Black   ];

    % 15
    coinIndex = find(coinTable{1} == 15);

    coinTable{2}(:,coinIndex) = [1 1 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Nickel.Diam USCoins.Dime.Diam 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1.2 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Nickel.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 16
    coinIndex = find(coinTable{1} == 16);

    coinTable{2}(:,coinIndex) = [1 1 1 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Nickel.Diam USCoins.Dime.Diam 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1.2 -2.4 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Nickel.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 17
    coinIndex = find(coinTable{1} == 17);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam USCoins.Dime.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2.2 -3.4 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 18
    coinIndex = find(coinTable{1} == 18);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam USCoins.Dime.Diam 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3.2 -4.4 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black   ];

    % 19
    coinIndex = find(coinTable{1} == 19);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 1];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Nickel.Diam USCoins.Dime.Diam];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4.2 -5.4]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Nickel.Color; ...
                                        USCoins.Dime.Color];

    % 20
    coinIndex = find(coinTable{1} == 20);

    coinTable{2}(:,coinIndex) = [1 1 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Dime.Diam USCoins.Dime.Diam 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 -5]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Dime.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 21
    coinIndex = find(coinTable{1} == 21);

    coinTable{2}(:,coinIndex) = [1 1 1 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Dime.Diam USCoins.Dime.Diam 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 -5]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Dime.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 22
    coinIndex = find(coinTable{1} == 22);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam USCoins.Dime.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 -5]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % 23
    coinIndex = find(coinTable{1} == 23);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam USCoins.Dime.Diam 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 -5]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color; ...
                                        USCoins.Dime.Color;...
                                        USCoins.Black   ];

    % 24
    coinIndex = find(coinTable{1} == 24);

    coinTable{2}(:,coinIndex) = [1 1 1 1 1 1];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Penny.Diam USCoins.Dime.Diam USCoins.Dime.Diam];

    coinTable{4}(:, 1, coinIndex) = [0 -1 -2 -3 -4 -5]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Penny.Color;...
                                        USCoins.Dime.Color; ...
                                        USCoins.Dime.Color];

    % 25
    coinIndex = find(coinTable{1} == 25);

    coinTable{2}(:,coinIndex) = [1 0 0 0 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Quarter.Diam 0 0 0 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 0 0 0 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Quarter.Color; ...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black;...
                                        USCoins.Black   ];
                                    
    % 41
    coinIndex = find(coinTable{1} == 41);

    coinTable{2}(:,coinIndex) = [1 1 1 1 0 0];

    coinTable{3}(:, coinIndex) = [USCoins.Penny.Diam USCoins.Nickel.Diam USCoins.Dime.Diam USCoins.Quarter.Diam 0 0];

    coinTable{4}(:, 1, coinIndex) = [0 -1.2 -2.4 -3.8 0 0]';

    coinTable{5}(:, :, coinIndex) = [USCoins.Penny.Color; ...
                                        USCoins.Nickel.Color;...
                                        USCoins.Dime.Color;...
                                        USCoins.Quarter.Color;...
                                        USCoins.Black;...
                                        USCoins.Black   ];

    % Save look up table 
%     save('CoinLookUpTable.mat')
end

for iCoinValue = 1:numel(coinValues)
    coinIndex = coinTable{1} == coinValues(iCoinValue);
    for ii = 1:maxNumberofCoins
        b5.(sprintf('Coin0%d_0%d_draw', iCoinValue, ii)) = ...
            DRAW_BOTH * coinTable{2}(ii, coinIndex);
        
        b5.(sprintf('Coin0%d_0%d_scale', iCoinValue, ii)) = ...
            [coinTable{3}(ii, coinIndex),coinTable{3}(ii, coinIndex)];
        
        b5.(sprintf('Coin0%d_0%d_pos', iCoinValue, ii))(1) = ...
            b5.(sprintf('Coin0%d_0%d_pos', iCoinValue, ii))(1) + ...
            coinTable{4}(ii,1, coinIndex).*xPosScaleFactor;
        
        b5.(sprintf('Coin0%d_0%d_color', iCoinValue, ii)) = ...
            coinTable{5}(ii,:, coinIndex);
    end
end
end