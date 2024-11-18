%%-----------------------------------------------------------------------%%
% filename:         MF52_MZ_Fit.m
% author(s):        Niek van Rossem
% Creation date:    02-11-2024
%%-----------------------------------------------------------------------%%

function [Tyre, xData, yData, Params] = MF52_MZ_Fit(CleanData, Tyre, Settings, f0, Fz0, R0, lambda)

    h = figure('Name', 'Parameter convergence');

    % find indices of limited dataset
    idx = find( ...
        CleanData.P >= Settings.minPress & ...
        CleanData.P <= Settings.maxPress & ...
        CleanData.IA >= Settings.minIA & ...
        CleanData.IA <= Settings.maxIA & ...
        CleanData.V >= Settings.minV & ...
        CleanData.V <= Settings.maxV);
    
    % add pressure to data file
    Tyre.Pressure = unique(CleanData.P(idx));
    Tyre.Pressure = Tyre.Pressure(1);
   
    % load already fitted Fy parameters
    Params_FY = [Tyre.PCY1, Tyre.PDY1, Tyre.PDY2, Tyre.PDY3, Tyre.PEY1, Tyre.PEY2, Tyre.PEY3, Tyre.PEY4, Tyre.PKY1, Tyre.PKY2, Tyre.PKY3, Tyre.PHY1, Tyre.PHY2, Tyre.PHY3, Tyre.PVY1, Tyre.PVY2, Tyre.PVY3, Tyre.PVY4];
  
    % calculate Fy
    FY_new = MF52_FY_model(Params_FY, [CleanData.SA(idx)', CleanData.FZ(idx)', CleanData.IA(idx)'], Fz0, lambda, Settings);
  
    % create input data array
    xData = horzcat(FY_new, CleanData.FZ(idx)', CleanData.SA(idx)', CleanData.IA(idx)');
    
    % create output data array
    yData = CleanData.MZ(idx)';
    
    % set solver options
    options = optimset( ...
        'MaxFunEvals', 1e25, ...
        'TolFun', 1e-10, ...
        'Display', 'off');
    
    % define function to be solved for the coefficients
    func = @(P, X) MF52_MZ_model(P, X, Tyre, Fz0, R0, lambda);
    
    % allocate space for parameters
    ParamsIter = zeros(Settings.IterSize, numel(f0));
    
    % create array with titles for figure
    TitleNames = [
        "QBZ1";
        "QBZ2";
        "QBZ3";
        "QBZ4";
        "QBZ5";
        "QBZ9";
        "QBZ10";
        "QCZ1";
        "QDZ1";
        "QDZ2";
        "QDZ3";
        "QDZ4";
        "QDZ6";
        "QDZ7";
        "QDZ8";
        "QDZ9";
        "QEZ1";
        "QEZ2";
        "QEZ3";
        "QEZ4";
        "QEZ5";
        "QHZ1";
        "QHZ2";
        "QHZ3";
        "QHZ4"
        ];
    
    % Bootstrapping technique
    for k = 1:Settings.IterSize
    
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
        
        % plot parameter changes
        if Settings.PlotFit == "Params"
            for n = 1:numel(Params)
                figure(h);
                subplot(5,5,n);
                bar([ParamsIter(:,n)], 'group');
                title(TitleNames(n));
                xlim([0 Settings.IterSize+1]);
            end

        elseif Settings.PlotFit == "RMS"
           figure(h);
           bar(resnorm, 'group');
           title("RMS error");
           xlim([0 Settings.IterSize+1]);

        end

        % update initial guess if it's an improvement
        if k > 1
    
            % if result is better than the best so far, update parameters
            if resnorm(k) <= min(resnorm)
                for n = 1:numel(Params)
                    f0(n) = Params(n) -1*eps*rand;
                end
    
            % if result is worse than best, keep best fit as initial guess
            else
                index = find(resnorm == min(resnorm));
                index = index(end);
                for n = 1:numel(Params)
                    f0(n) = ParamsIter(index,n) -1*eps*rand;
                end
            end
        end
    
        % update figure name
        set(figure(h), 'Name', [' MF 5.2 Free rolling self-aligning moment - Iteration: ', num2str(k), ...
            ' | RMS ERROR: ', num2str(sqrt(resnorm(k))), ' Nm']);
    end
        
    % find the best iteration (should be the last)
    idx = find(resnorm == min(resnorm));

    % extract best fit parameters
    Params = ParamsIter(idx(1),:);
    
    % Add parameters to Tyre structure
    Tyre.QBZ1 = Params(1);
    Tyre.QBZ2 = Params(2);
    Tyre.QBZ3 = Params(3);
    Tyre.QBZ4 = Params(4);
    Tyre.QBZ5 = Params(5);
    Tyre.QBZ9 = Params(6);
    Tyre.QBZ10 = Params(7);
    Tyre.QCZ1 = Params(8);
    Tyre.QDZ1 = Params(9);
    Tyre.QDZ2 = Params(10);
    Tyre.QDZ3 = Params(11);
    Tyre.QDZ4 = Params(12);
    Tyre.QDZ6 = Params(13);
    Tyre.QDZ7 = Params(14);
    Tyre.QDZ8 = Params(15);
    Tyre.QDZ9 = Params(16);
    Tyre.QEZ1 = Params(17);
    Tyre.QEZ2 = Params(18);
    Tyre.QEZ3 = Params(19);
    Tyre.QEZ4 = Params(20);
    Tyre.QEZ5 = Params(21);
    Tyre.QHZ1 = Params(22);
    Tyre.QHZ2 = Params(23);
    Tyre.QHZ3 = Params(24);
    Tyre.QHZ4 = Params(25);
    
    % add resnorm as well
    Tyre.Resnorm_MZ = sqrt(min(resnorm));

    % add predefined parameters
    Tyre.Fz0 = Fz0;
    
end

