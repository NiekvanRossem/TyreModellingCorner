function [Tyre, CleanData, RawData, SummaryData, Figures] = PreProcessor(Settings)

    % load data
    [RawData, Tyre, Figures] = LoadTyreData(Settings);

    % Splice data into individual sweeps
    [ZeroCrossings, Figures] = IdentifySweep(RawData, Figures, Settings);

    % Clean up and resample sweeps
    [CleanData, RawData, SummaryData, Figures] = SpliceData(RawData, Settings, Figures, ZeroCrossings);

end