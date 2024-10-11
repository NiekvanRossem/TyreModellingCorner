%%-----------------------------------------------------------------------%%
% filename:         MF52_FY_Fit.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function [Tyre, xData, yData, Params] = MF52_MX_Fit(CleanData, Tyre, Settings, f0, Fz0, R0, lambda)

    h = figure('Name', 'Parameter convergence');

    % find indices of limited dataset
    idx = find( ...
        CleanData.P >= Settings.minPress & ...
        CleanData.P <= Settings.maxPress & ...
        CleanData.IA >= Settings.minIA & ...
        CleanData.IA <= Settings.maxIA & ...
        CleanData.V >= Settings.minV & ...
        CleanData.V <= Settings.maxV);
    
    % add pressure and camber to data file
    Tyre.Pressure = unique(CleanData.P(idx));
    Tyre.Pressure = Tyre.Pressure(1);
   
    Params_FY = [Tyre.PCY1, Tyre.PDY1, Tyre.PDY2, Tyre.PDY3, Tyre.PEY1, Tyre.PEY2, Tyre.PEY3, Tyre.PEY4, Tyre.PKY1, Tyre.PKY2, Tyre.PKY3, Tyre.PHY1, Tyre.PHY2, Tyre.PHY3, Tyre.PVY1, Tyre.PVY2, Tyre.PVY3, Tyre.PVY4];

    FY_new = MF52_FY_model(Params_FY, [CleanData.SA(idx)', CleanData.FZ(idx)', CleanData.IA(idx)'], Fz0, lambda, Settings);

    % create input data array
    xData = horzcat(FY_new, CleanData.FZ(idx)', CleanData.IA(idx)');
    
    % create output data array
    yData = CleanData.MX(idx)';
    
    % set solver options
    options = optimset( ...
        'MaxFunEvals', 1e25, ...
        'TolFun', 1e-10, ...
        'Display', 'off');
    
    % define function to be solved for the coefficients
    func = @(P, X) MF52_MX_model(P, X, Fz0, R0, lambda);
    
    % allocate space for parameters
    ParamsIter = zeros(Settings.IterSize, numel(f0));
    
    % create array with titles for figure
    TitleNames = [
        "QSX1"; 
        "QSX2"; 
        "QSX3"; 
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
                subplot(1,3,n);
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
    Tyre.QSX1 = Params(1);
    Tyre.QSX2 = Params(2);
    Tyre.QSX3 = Params(3);
    
    % add resnorm as well
    Tyre.Resnorm_MX = sqrt(min(resnorm));

    % add predefined parameters
    Tyre.Fz0 = Fz0;
    
end

