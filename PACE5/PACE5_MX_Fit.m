%%-----------------------------------------------------------------------%%
% filename:         PACE5_MX_Fit.m
% author(s):        Niek van Rossem
% Creation date:    22-09-2024
%%-----------------------------------------------------------------------%%

function [Tyre, xData, yData, Params] = PACE5_MX_Fit(CleanData, Tyre, Settings, f0)

    h = figure('Name', 'Parameter convergence');

    % find indices of limited dataset
    idx = find( ...
        CleanData.P >= Settings.minPress & ...
        CleanData.P <= Settings.maxPress & ...
        CleanData.IA >= Settings.minIA & ...
        CleanData.IA <= Settings.maxIA & ...
        CleanData.V >= Settings.minV & ...
        CleanData.V <= Settings.maxV);
    
    % create input data array
    xData = horzcat(CleanData.SA(idx)', CleanData.FZ(idx)');
    
    % create output data array
    yData = CleanData.MX(idx)';
    
    % set solver options
    options = optimset( ...
        'MaxFunEvals', 1e16, ...
        'TolFun', 1e-7, ...
        'Display', 'off');
    
    % define function to be solved for the coefficients
    func = @(P, X) Pacejka5_model(P, X, Settings);
    
    ParamsIter = zeros(Settings.IterSize, numel(f0));
    
    % create array with titles for figure
    TitleNames = ["D1"; "D2"; "B"; "C"; "Bp"; "Sv"];
    
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
            subplot(2,3,n);
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
        set(figure(h), 'Name', [' PACE5 Free rolling overturning moment - Iteration: ', num2str(k), ...
            ' | RMS ERROR: ', num2str(sqrt(resnorm(k))), ' N']);
    end
        
    idx = find(resnorm == min(resnorm));

    % extract best fit parameters
    Params = ParamsIter(idx(1),:);
    
    % Add parameters to Tyre structure
    Tyre.Do1 = Params(1);
    Tyre.Do2 = Params(2);
    Tyre.Bo  = Params(3);
    Tyre.Co  = Params(4);
    Tyre.Bpo = Params(5);
    
    % only if Svy was included in the fitting process
    try
        Tyre.Svo = Params(6);
    end
    
    % add resnorm as well
    Tyre.Resnorm_MX = sqrt(min(resnorm));
end

