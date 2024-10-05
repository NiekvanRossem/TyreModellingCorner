%%-----------------------------------------------------------------------%%
% filename:         Settings.m
% author(s):        Niek van Rossem
% Creation date:    22-09-2024
%%-----------------------------------------------------------------------%%

function Settings = Settings()

    % set to 1 if you want to plot raw data
    Settings.PlotFigs = 0;

    % slip angle / slip ratio step size for downsampling
    Settings.StepSize = 1;

    % smoothing factor for spline fit
    Settings.LatSmoothing = 0.1;
    Settings.LongSmoothing = 0.9999;

    % select round and run
    Settings.Round = 9;
    Settings.Run = [4, 5, 6];


end

