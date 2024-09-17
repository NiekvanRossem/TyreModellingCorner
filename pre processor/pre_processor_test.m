%% Prepare workspace

% clear everything
clear; close all; clc;

% set all figures to docked mode
set(0,'DefaultFigureWindowStyle','docked');

%% Import settings

Settings.PlotFigs = 1;
%Settings.BreakIn = 1;

%% Choose round and run
Round = 9;
Run = 14;

%% load data
[data, Tyre, Figures] = LoadTyreData(Round, Run, Settings);

%% Splice data into individual sweeps

ZeroCrossings = IdentifySweep(data, Figures, Settings);
