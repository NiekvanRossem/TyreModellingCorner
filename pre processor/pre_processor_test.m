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
