%%-----------------------------------------------------------------------%%
% filename:         MF52_main.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

%% Documentation
% -
%

%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Initialise

% Import settings
Settings = Settings();

Settings.StepSize = 1;

% add units used to settings structure
Settings.AngleUnit = "deg";
Settings.ForceUnit = "N";
Settings.LengthUnit = "m";
Settings.PressUnit = "bar";

% turn raw data plots on
Settings.PlotFigs = 1;

% Choose round and run
Settings.Round = 9;
Settings.Run = [8,9];

% Select limits for camber and pressure
Settings.minPress   = 0.78;
Settings.maxPress   = 0.88;
Settings.minIA      = -1;
Settings.maxIA      =  5;
Settings.minV       = 10;
Settings.maxV       = 13;

% Limit slip angles (MZ only)
Settings.minSA = -12;
Settings.maxSA = 12;

% sign convention. Set to either "ISO_A", "ISO_B", or "SAE".
Settings.Convention = "ISO_B";

% set scaling factors equal to 1
L.VMx  = 1;
L.Mx   = 1;
L.mu_y = 1;
L.Cy   = 1;
L.Hy   = 1;
L.Ky   = 1;
L.Vy   = 1;
L.gamma_z = 1;
L.t    = 1;
L.r    = 1;

% set nominal load and unloaded radius
Fz0 = 600;
R0  = 25.4e-3*16.2/2;

%% Run pre-processor

[Tyre, CleanData, RawData, SummaryData, Figures] = PreProcessor(Settings);

Tyre.Model = "MF52";
Tyre.Convention = Settings.Convention;

%% MF 5.2 Side force fitting

% set number of iterations
Settings.IterSize = 10;

% set to either RawData or CleanData
Settings.Comparison = "CleanData";

% set to either RMS or Params
Settings.PlotFit = "Params";

% set mutation parameter
Settings.eps = 1;

% initial guess
f0 = zeros(1,18);

% fit
[Tyre, xData, yData, Params] = MF52_FY_Fit(CleanData, Tyre, Settings, f0, Fz0);

% compare result
MF52_Comparison(RawData, CleanData, xData, yData, Params, "FY", Fz0, R0, L, Tyre, Settings);

clear f0 xData yData Params;

%% MF 5.2 Overturning moment fitting

% set number of iterations
Settings.IterSize = 10;

% set mutation parameter
Settings.eps = 1;

% initial guess
f0 = zeros(1,3);

% fit
[Tyre, xData, yData, Params] = MF52_MX_Fit(CleanData, Tyre, Settings, f0, Fz0, R0, L);

% compare result
MF52_Comparison(RawData, CleanData, xData, yData, Params, "MX", Fz0, R0, L, Tyre, Settings);

clear f0 xData yData Params;

%% MF 5.2 Self aligning moment fitting

% set number of iterations
Settings.IterSize = 50;

% set mutation parameter
Settings.eps = 1;

% initial guess
f0 = zeros(1,25);

% fit
[Tyre, xData, yData, Params] = MF52_MZ_Fit(CleanData, Tyre, Settings, f0, Fz0, R0, L);

% compare result
MF52_Comparison(RawData, CleanData, xData, yData, Params, "MZ", Fz0, R0, L, Tyre, Settings)

clear f0 xData yData Params;
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
fy = Pacejka10_model([Tyre.Cy Tyre.Dy1, Tyre.Dy2, Tyre.Ey, Tyre.Py, 0, 0, 0], X, 600, 1, Settings);
mz = Pacejka10_model([Tyre.Cz Tyre.Dz1, Tyre.Dz2, Tyre.Ez, Tyre.Pz, 0, 0, 0], X, 600, 1, Settings);

trail = mz./fy;

% reshape for plotting
slip = reshape(slip, 100, []);
FZ = reshape(FZ, 100, []);
trail = reshape(trail, 100, []);

figure; surf(slip, FZ, 1e3*trail); box on; grid minor;
title('Pneumatic trail');
xlabel('SA (deg)');
ylabel('FZ (N)');
zlabel('t (mm)');
