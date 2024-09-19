%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Import settings

Settings.PlotFigs = 0;
Settings.StepSize = 0.1;
Settings.Smoothing = 0.1;
%Settings.BreakIn = 1;
Settings.UseOldMyCalc = 0;

%% Choose round and run
Round = 9;
Run = [4, 5, 6];

%% load data
[RawData, Tyre, Figures] = LoadTyreData(Round, Run, Settings);

%% Splice data into individual sweeps

[ZeroCrossings, Figures] = IdentifySweep(RawData, Figures, Settings);

%% Clean up and resample sweeps

[CleanData, RawData, SummaryData, Figures] = SpliceData(RawData, Settings, Figures, ZeroCrossings);

%%
idx = find(SummaryData.IA == 0 & SummaryData.FZ > 1000);
figure; hold all;
plot(SummaryData.P(idx), SummaryData.MUY1(idx), 'o');
plot(SummaryData.P(idx), SummaryData.MUY2(idx), 'o');

%% PACE5 Side force fitting

% Select limits for camber and pressure
minPress = 0.78;
maxPress = 0.88;
minIA = -1;
maxIA =  1;
minV  = 10;
maxV  = 13;

% find indices of limited dataset
idx = find( ...
    CleanData.P >= minPress & ...
    CleanData.P <= maxPress & ...
    CleanData.IA >= minIA & ...
    CleanData.IA <= maxIA & ...
    CleanData.V >= minV & ...
    CleanData.V <= maxV);

% create input data array
xData = horzcat(CleanData.SA(idx)', CleanData.FZ(idx)');

% create output data array
yData = CleanData.FY(idx)';

% initial guess
f0 = [2.557, -0.1332, 0.18, 1.78, -0.4893, 14.2];

% set solver options
options = optimset( ...
    'MaxFunEvals', 1e16, ...
    'TolFun', 1e-10, ...
    'Display', 'off');

% define function to be solved for the coefficients
func = @(P, X) Pacejka5_model(P, X);

IterSize = 50;
%resnorm = zeros(1, IterSize);
ParamsIter = zeros(IterSize, numel(f0));

eps = 1e-2;

% Bootstrapping technique
for k = 1:IterSize

    % solve
    [Params, resnorm(k)] = lsqcurvefit( ...
        func, ...       % function to be fitted
        f0, ...         % initial guess
        xData, ...      % dependent data
        yData, ...      % independent data
        [], [], ...     % bounds
        options);       % options
    
    % collect parameters for this iteration
    ParamsIter(k,:) = Params;

    for n = 1:numel(Params)
        figure(1001);
        subplot(2,3,n);
        bar([ParamsIter(:,n)], 'group');
        %title(['Params(' num2str(n) ') = ' Params_str{n}]);
        xlim([0 IterSize]);
    end

    % update initial guess
    if k > 1
        if resnorm(k) <= min(resnorm)
            for n = 1:numel(Params)
                f0(n) = Params(n) -1*eps*rand;
            end
        else
            index = find(resnorm == min(resnorm));
            index = index(end);
            for n = 1:numel(Params)
                f0(n) = ParamsIter(index,n) -1*eps*rand;
            end
        end
    end

    set(figure(1001), 'Name', [' PACE5 Free rolling lateral force - Iteration: ', num2str(k), ...
        ' | RMS ERROR: ', num2str(sqrt(resnorm(k))), ' N']);
    %drawnow;
end

%% Compare fit to original data
final = find(min(resnorm));

Params = ParamsIter(final,:);

% select sweep to compare
n = 6;

% left and right indices
L = ZeroCrossings(n); R = ZeroCrossings(n+1);

slip = linspace(-12, 12, 100);
FZ = RawData.FZ(L+1)*ones(size(slip));

FY_sim = Pacejka5_model(Params, [slip', FZ']);

figure(2002); clf; hold all;
plot(RawData.SA(L:R), RawData.FY(L:R), '.', 'MarkerSize', 2);
plot(slip, FY_sim, 'LineWidth',1);
box on; grid minor;
xlabel('SA (rad)');
ylabel('FY (N)');

FZ = linspace(0, 3500, 100); 
slip = linspace(-12, 12, 100);
[slip, FZ] = meshgrid(slip, FZ);
 
FZ = reshape(FZ, 100*100, []);
slip = reshape(slip, 100*100, []);
X = [slip, FZ];

FY = Pacejka5_model(Params, X);

slip = reshape(slip, 100, []);
FZ = reshape(FZ, 100, []);
FY = reshape(FY, 100, []);

figure(3003); clf; surf(slip, FZ, FY);

%%

idx = find(CleanData.P >= minPress & CleanData.P <= maxPress & CleanData.IA >= minIA & CleanData.IA <= maxIA);

NewData.SA = RawData.SA(idx);
NewData.FY = RawData.FY(idx);
NewData.FZ = RawData.FZ(idx);

figure(22002); clf;
plot3(NewData.SA, NewData.FZ, NewData.FY, '.');

%%
Tyre.Dy1 = Params(1);
Tyre.Dy2 = Params(2);
Tyre.By  = Params(3);
Tyre.Cy  = Params(4);
Tyre.Bpy = Params(5);
try
    Tyre.Svy = Params(6);
end
Tyre.Resnorm = sqrt(min(resnorm));