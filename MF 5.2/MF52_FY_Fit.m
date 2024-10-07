%%-----------------------------------------------------------------------%%
% filename:         MF52_FY_Fit.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function [Tyre, xData, yData, Params] = MF52_FY_Fit(CleanData, Tyre, Settings, f0, Fz0)

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
    Tyre.Camber   = unique(CleanData.IA(idx));
    Tyre.Camber   = Tyre.Camber(1);

    % create input data array
    xData = horzcat(CleanData.SA(idx)', CleanData.FZ(idx)', CleanData.IA(idx)');
    
    % create output data array
    yData = CleanData.FY(idx)';
    
    % set solver options
    options = optimset( ...
        'MaxFunEvals', 1e25, ...
        'TolFun', 1e-10, ...
        'Display', 'off');
    
    % set scaling factors equal to 1
    lambda.mu_y = 1;
    lambda.Cy   = 1;
    lambda.Hy   = 1;
    lambda.Vy   = 1;

    % define function to be solved for the coefficients
    func = @(P, X) MF52_FY_model(P, X, Fz0, lambda, Settings);
    
    % allocate space for parameters
    ParamsIter = zeros(Settings.IterSize, numel(f0));
    
    % create array with titles for figure
    TitleNames = [
        "PCY1"; 
        "PDY1"; 
        "PDY2"; 
        "PDY3"; 
        "PEY1"; 
        "PEY2"; 
        "PEY3"; 
        "PEY4"; 
        "PKY1"; 
        "PKY2"; 
        "PKY3"; 
        "PHY1";
        "PHY2";
        "PHY3";
        "PVY1";
        "PVY2";
        "PVY3";
        "PVY4"
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
        for n = 1:numel(Params)
            figure(h);
            subplot(3,6,n);
            bar([ParamsIter(:,n)], 'group');
            title(TitleNames(n));
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
        set(figure(h), 'Name', [' MF 5.2 Free rolling lateral force - Iteration: ', num2str(k), ...
            ' | RMS ERROR: ', num2str(sqrt(resnorm(k))), ' N']);
    end
        
    % find the best iteration (should be the last)
    idx = find(resnorm == min(resnorm));

    % extract best fit parameters
    Params = ParamsIter(idx(1),:);
    
    % Add parameters to Tyre structure
    Tyre.PCY1 = Params(1);
    Tyre.PDY1 = Params(2);
    Tyre.PDY2 = Params(3);
    Tyre.PDY3 = Params(4);
    Tyre.PEY1 = Params(5);
    Tyre.PEY2 = Params(6);
    Tyre.PEY3 = Params(7);
    Tyre.PEY4 = Params(8);
    Tyre.PKY1 = Params(9);
    Tyre.PKY2 = Params(10);
    Tyre.PKY3 = Params(11);
    Tyre.PHY1 = Params(12);
    Tyre.PHY2 = Params(13);
    Tyre.PHY3 = Params(14);
    Tyre.PVY1 = Params(15);
    Tyre.PVY2 = Params(16);
    Tyre.PVY3 = Params(17);
    Tyre.PVY4 = Params(18);
    
    % add resnorm as well
    Tyre.Resnorm_FY = sqrt(min(resnorm));

    % add predefined parameters
    Tyre.Fz0 = Fz0;
    %Tyre.lambda.mu = 1;

end

