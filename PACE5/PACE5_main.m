%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Initialise

% Import settings
Settings = Settings();

% Choose round and run
Settings.Round = 9;
Settings.Run = [4, 5, 6];

% Select limits for camber and pressure
Settings.minPress   = 0.78;
Settings.maxPress   = 0.88;
Settings.minIA      = -1;
Settings.maxIA      =  1;
Settings.minV       = 10;
Settings.maxV       = 13;

%% Run pre-processor

[Tyre, CleanData, RawData, SummaryData, Figures] = PreProcessor(Settings);

Tyre.Model = "PACE5";

%% PACE5 Side force fitting

% set number of iterations
Settings.IterSize = 10;

% set mutation parameter
Settings.eps = 1e-2;

% initial guess
f0 = [2.557, -0.1332, 0.18, 1.78, -0.4893, 14.2];

% fit
[Tyre, xData, yData, Params] = PACE5_FY_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "FY");

%% PACE5 Overturning moment fitting

% set number of iterations
Settings.IterSize = 50;

% set mutation parameter
Settings.eps = 1;

% initial guess
f0 = [-61.2, 10, 0.37, 0.000172, -0.0007, -4.34];

% fit
[Tyre, xData, yData, Params] = PACE5_MX_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "MX");

%% PACE5 Self aligning moment fitting

% set number of iterations
Settings.IterSize = 5;

% set mutation parameter
Settings.eps = 1e-2;

% initial guess
f0 = [0.02, 0.03, 0.18, 3, -0.3, 32];

% fit
[Tyre, xData, yData, Params] = PACE5_MZ_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "MZ");

%% Pneumatic trail
% 
% % create dependent variable grid
% FZ = linspace(0, 2500, 100); 
% slip = linspace(-15, 15, 100);
% [slip, FZ] = meshgrid(slip, FZ);
% 
% % convert to input array
% FZ = reshape(FZ, 100*100, []);
% slip = reshape(slip, 100*100, []);
% X = [slip, FZ];
% 
% 
% % calculate Fy
% out1 = Pacejka5_model([Tyre.Dy1, Tyre.Dy2, Tyre.By, Tyre.Cy, Tyre.Bpy, 0], X);
% out2 = Pacejka5_model([Tyre.Dz1, Tyre.Dz2, Tyre.Bz, Tyre.Cz, Tyre.Bpz, 0], X);
% 
% trail = out2./out1;
% 
% % reshape for plotting
% slip = reshape(slip, 100, []);
% FZ = reshape(FZ, 100, []);
% trail = reshape(trail, 100, []);
% 
% figure; surf(slip, FZ, trail);
% 
