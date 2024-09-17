function [FY_fit, MZ_fit, MX_fit, press] = SplineFit(data, PlotFigs, Limits, Tyre)
    
    if ~isempty(data)
    %% Select subset of data
        
    % create index vector
    index = find( ...
        data.P  >= Limits.minpress & ...
        data.P  <= Limits.maxpress & ...
        data.IA >= Limits.mincamber & ...
        data.IA <= Limits.maxcamber & ...
        data.FZ >= Limits.minload & ...
        data.FZ <= Limits.maxload);
    
    % filter data
    data_subset = data(index, :);
    
    % find tyre pressure
    press = mean(data_subset.P);

    % Set up fittype and options.
    ft = 'cubicinterp';
    opts = fitoptions('Method', 'CubicSplineInterpolant');
    opts.ExtrapolationMethod = 'none';
    opts.Normalize = 'on';
    
    %% Side force fit
    
    % reshape data for spline fit
    [xData_FY, yData_FY, zData_FY] = prepareSurfaceData(data_subset.FZ, data_subset.SA, data_subset.FY);
    
    % Fit model to data.
    [FY_fit, ~] = fit([xData_FY, yData_FY], zData_FY, ft, opts);
    
    %% Self-aligning moment fit
    
    % reshape data for spline fit
    [xData_MZ, yData_MZ, zData_MZ] = prepareSurfaceData(data_subset.FZ, data_subset.SA, data_subset.MZ);
    
    % Fit model to data.
    [MZ_fit, ~] = fit([xData_MZ, yData_MZ], zData_MZ, ft, opts);
    
    %% overturning moment fit
    
    % reshape data for spline fit
    [xData_MX, yData_MX, zData_MX] = prepareSurfaceData(data_subset.FZ, data_subset.SA, data_subset.MX);
    
    % Fit model to data.
    [MX_fit, ~] = fit([xData_MX, yData_MX], zData_MX, ft, opts);
    
    %% Plot fitresult
    if PlotFigs == 1
        figure('Name', 'Fit results');
        figtitle1 = "Processed TTC dataset | " + Tyre.DataOrigin + " (" + Tyre.Run + ")";
        figtitle2 = Tyre.Brand + " " + Tyre.Item + " " + Tyre.Dimensions + " (" + Tyre.Compound + " compound) on " + Tyre.RimWidth + " rim";
        figtitle3 = "Pressure: " + num2str(round(mean(data_subset.P), 2)) + " bar | Camber: " + num2str(round(mean(data_subset.IA))) + " deg";
        sgtitle({figtitle1, figtitle2, figtitle3});
        subplot(1,3,1);
            plot(FY_fit, [xData_FY, yData_FY], zData_FY); hold on;
            xlabel('Vertical load (N)');
            ylabel('Slip angle (deg)');
            zlabel('Side force (N)');
            title('FY')
            grid minor;
        subplot(1,3,2);
            plot(MZ_fit, [xData_MZ, yData_MZ], zData_MZ); hold on;
            xlabel('Vertical load (N)');
            ylabel('Slip angle (deg)');
            zlabel('Self-aligning moment (Nm)');
            title('MZ');
            grid minor;
        subplot(1,3,3);
            plot(MX_fit, [xData_MX, yData_MX], zData_MX); hold on;
            xlabel('Vertical load (N)');
            ylabel('Slip angle (deg)');
            zlabel('Overturning moment (Nm)');
            title('MX');
            grid minor;
    end
    end
end