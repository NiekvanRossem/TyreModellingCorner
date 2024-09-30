%%-----------------------------------------------------------------------%%
% filename:         Pacejka10_FY_Fit.m
% author(s):        Niek van Rossem
% Creation date:    30-09-2024
%%-----------------------------------------------------------------------%%

function [Tyre, xData, yData, Params] = Pacejka10_FY_Fit(CleanData, Tyre, Settings, f0, Fz0)

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
    xData = horzcat(CleanData.SA(idx)', CleanData.FZ(idx)');
    
    % create output data array
    yData = CleanData.FY(idx)';
    
    % set solver options
    options = optimset( ...
        'MaxFunEvals', 1e16, ...
        'TolFun', 1e-7, ...
        'Display', 'off');
    
    % define function to be solved for the coefficients
    func = @(P, X) Pacejka10_model(P, X, Fz0, 1, Settings);
    
    ParamsIter = zeros(Settings.IterSize, numel(f0));
    
    % create array with titles for figure
    TitleNames = ["C"; "D1"; "D2"; "E"; "P"; "S_H1"; "S_H2"; "S_V"];
    
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
            subplot(2,4,n);
            bar([ParamsIter(:,n)], 'group');
            title(TitleNames(n));
            xlim([0 Settings.IterSize]);
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
        set(figure(h), 'Name', [' Pacejka10 Free rolling lateral force - Iteration: ', num2str(k), ...
            ' | RMS ERROR: ', num2str(sqrt(resnorm(k))), ' N']);
    end
        
    % find the best iteration (should be the last)
    idx = find(resnorm == min(resnorm));

    % extract best fit parameters
    Params = ParamsIter(idx(1),:);
    
    % Add parameters to Tyre structure
    Tyre.Cy     = Params(1);
    Tyre.Dy1    = Params(2);
    Tyre.Dy2    = Params(2);
    Tyre.Ey     = Params(3);
    Tyre.Py     = Params(4);
    Tyre.S_Hy1  = Params(5);
    Tyre.S_Hy2  = Params(5);
    Tyre.S_vy   = Params(5);
    
    % add resnorm as well
    Tyre.Resnorm_FY = sqrt(min(resnorm));

    % add predefined parameters
    Tyre.Fz0 = Fz0;
    Tyre.lambda = 1;

end

