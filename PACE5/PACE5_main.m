%%-----------------------------------------------------------------------%%
% filename:         PACE5_main.m
% author(s):        Niek van Rossem
% Creation date:    22-09-2024
%%-----------------------------------------------------------------------%%

%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Initialise

% Import settings
Settings = Settings();

% add units used to settings structure
Settings.AngleUnit  = "deg";
Settings.ForceUnit  = "N";
Settings.LengthUnit = "m";
Settings.PressUnit  = "bar";

% turn raw data plots on
Settings.PlotFigs = 1;

% Choose round and run
Settings.Round = 9;
Settings.Run = [20, 21];

% Select limits for camber and pressure
Settings.minPress   = 0.78;
Settings.maxPress   = 0.88;
Settings.minIA      = -1;
Settings.maxIA      =  1;
Settings.minV       = 10;
Settings.maxV       = 13;

% Limit slip angles (MZ only)
Settings.minSA = -10;
Settings.maxSA =  10;

% sign convention. Set to either "ISO_A", "ISO_B", or "SAE".
Settings.Convention = "ISO_B";

%% Run pre-processor

[Tyre, CleanData, RawData, SummaryData, Figures] = PreProcessor(Settings);

Tyre.Model = "PACE5";
Tyre.Convention = Settings.Convention;

%% PACE5 Side force fitting

% set number of iterations
Settings.IterSize = 10;

% set mutation parameter
Settings.eps = 1e-2;

% initial guess
f0 = [
    -2.557, ...     % D1
    -0.1332, ...    % D2
     0.18, ...      % B
     1.78, ...      % C
    -0.4893, ...    % Bp
    14.2 ...        % Sv
    ];

% fit
[Tyre, xData, yData, Params] = PACE5_FY_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "FY", Settings);

%% PACE5 Overturning moment fitting

% set number of iterations
Settings.IterSize = 50;

% set mutation parameter
Settings.eps = 1;

% initial guess
f0 = [
    -100.6, ...     % D1
    16.4, ...       % D2
    0.37, ...       % B
    5.4e-5, ...     % C
    -3.7e-4, ...    % Bp
    -4.34 ...       % Sv
    ];

% fit
[Tyre, xData, yData, Params] = PACE5_MX_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "MX", Settings);

%% PACE5 Self aligning moment fitting

% set number of iterations
Settings.IterSize = 5;

% set mutation parameter
Settings.eps = 1e-2;

% initial guess
f0 = [-0.02, 0.03, 0.18, 3, -0.3, 32];

% fit
[Tyre, xData, yData, Params] = PACE5_MZ_Fit(CleanData, Tyre, Settings, f0);

% compare result
PACE5_Comparison(CleanData, xData, yData, Params, "MZ", Settings);

%% Pneumatic trail

% create dependent variable grid
FZ = linspace(500, 2500, 100); 
slip = linspace(-15, 15, 100);
[slip, FZ] = meshgrid(slip, FZ);

% convert to input array
FZ = reshape(FZ, 100*100, []);
slip = reshape(slip, 100*100, []);
X = [slip, FZ];


% calculate Fy
out1 = Pacejka5_model([Tyre.Dy1, Tyre.Dy2, Tyre.By, Tyre.Cy, Tyre.Bpy, 0], X, Settings);
out2 = Pacejka5_model([Tyre.Dz1, Tyre.Dz2, Tyre.Bz, Tyre.Cz, Tyre.Bpz, 0], X, Settings);

trail = out2./out1;

% reshape for plotting
slip = reshape(slip, 100, []);
FZ = reshape(FZ, 100, []);
trail = reshape(trail, 100, []);

figure; surf(slip, FZ, 1e3*trail); box on; grid minor;
title('Pneumatic trail');
xlabel('SA (deg)');
ylabel('FZ (N)');
zlabel('t (mm)');
