% NOTE: This was an attempt to fit the rolling resistance moment equation
% from Pacejka's book to the TTC data. However as was pointed out on the
% forum no My signal exists. I tried to make one by multiplying the Fx and
% RL signals at SL = 0, but did not realise the bearing resistance is
% included in this. Therefore while this script is fully functional, the
% output is of no use 
% ~Niek

%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Import settings

Settings.PlotFigs = 0;
Settings.StepSize = 1;
Settings.Smoothing = 0.1;
%Settings.BreakIn = 1;

%% Choose round and run
Round = 9;
Run = [11, 12];

%% load data
[RawData, Tyre, Figures] = LoadTyreData(Round, Run, Settings);

%% Splice data into individual sweeps

[ZeroCrossings, Figures] = IdentifySweep(RawData, Figures, Settings);

%% Clean up and resample sweeps

[CleanData, RawData, Figures] = SpliceData(RawData, Settings, Figures, ZeroCrossings);

%% Fit rolling resistance model (test)

% select subset of clean data
idx = find(CleanData.SA == 0);

% collect output data
yData = CleanData.MY(idx)';

% collect input data
xData = horzcat(CleanData.FX(idx)', ...
    CleanData.FZ(idx)', ...
    CleanData.V(idx)', ...
    CleanData.IA(idx)', ...
    CleanData.P(idx)');

xData(:,1) = 0;

% initial guess
f0 = [0, 0, 0, 0, 0, 0, 0, 0];

% set solver options
options = optimset( ...
    'MaxFunEvals', 1e16, ...
    'TolFun', 1e-10, ...
    'Display', 'off');

% set constant parameters
R0 = 8*25.4*1e-3;
FZ0 = 600;
V0 = 11.15;
P0 = 0.82;
LMY = 1;

% define function to be solved for the coefficients
func = @(P, X) RollingResistance_model(P, X, R0, FZ0, V0, P0, LMY);

% solve
[Params, resnorm, residual] = lsqcurvefit( ...
    func, ...       % function to be fitted
    f0, ...         % initial guess
    xData, ...      % dependent data
    yData, ...      % independent data
    [], [], ...     % bounds
    options);       % options

%% Compare model to original data


idx = find(xData(:,3) == 11.2 & xData(:,4) == 0 & xData(:,5) > 0.81 & xData(:,5) < 0.83);
testX = xData(idx,:);
testY = yData(idx,:);

evalX = testX;

temp = RollingResistance_model(Params, evalX, R0, FZ0, V0, P0, LMY);

eval = horzcat(testX, temp);
clear temp;

eval = sortrows(eval, 6);

figure(2); clf; hold all; grid minor;
plot(testX(:,2), testY, 'o');
plot(eval(:,2), eval(:,6));