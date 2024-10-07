%%-----------------------------------------------------------------------%%
% filename:         MF52_comparison.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function [] = MF52_Comparison(CleanData, xData, yData, Params, Mode, Fz0, Settings)
    %% Documentation
    %
    %

    %% Compare fit to original data (curve plots)
    
    % set scaling factors equal to 1
    lambda.mu_y = 1;
    lambda.Cy   = 1;
    lambda.Hy   = 1;
    lambda.Vy   = 1;

    % find data for first camber angle
    camberAngle  = unique(xData(:,3));
    idx = find(xData(:,3) == camberAngle(1));
    newDataX = xData(idx,:);
    newDataY = yData(idx);

    % find vertical loads
    verticalLoad = unique(newDataX(:,2));

    % set figure formatting (zero camber)
    figure('Name', 'Curve comparison, 0 deg camber'); hold all;
    title({CleanData.source, CleanData.tireid});
    box on; grid minor;
    if Mode == "FY"
        xlabel('SA (deg)');
        ylabel('FY (N)');
    elseif Mode == "MX"
        xlabel('SA (deg)');
        ylabel('MX (Nm)');
    elseif Mode == "MZ"
        xlabel('SA (deg)');
        ylabel('MZ (Nm)');
    end

    % slip angle vector
    slip = linspace(-15, 15, 100)';
    xline(0, 'k'); yline(0, 'k');
    
    % loop over all vertical loads
    for n = 1:numel(unique(newDataX(:,2)))
        
        % find indices
        idx = find(newDataX(:,2) == verticalLoad(n));
        
        % calculate Fy from fit
        out = MF52_FY_model(Params, [slip, verticalLoad(n)*ones(size(slip)), camberAngle(1)*ones(size(slip))], Fz0, lambda, Settings);
    
        % plot data and fit
        plot(newDataX(idx,1), newDataY(idx), 'ro');
        plot(slip, out, 'b-');
    end
    
    % %% Compare fit to original data (surface plot)
    % 
    % % create dependent variable grid
    % FZ = linspace(0, 2500, 100); 
    % slip = linspace(-15, 15, 100);
    % [slip, FZ] = meshgrid(slip, FZ);
    % 
    % % convert to input array
    % FZ = reshape(FZ, 100*100, []);
    % slip = reshape(slip, 100*100, []);
    % X = [slip, FZ];
    % 
    % % calculate Fy
    % out = Pacejka10_model(Params, X, Fz0, 1, Settings);
    % 
    % % reshape for plotting
    % slip = reshape(slip, 100, []);
    % FZ = reshape(FZ, 100, []);
    % out = reshape(out, 100, []);
    % 
    % % plot results
    % figure('Name', 'Surface plot comparison'); clf; hold all;
    % title({CleanData.source, CleanData.tireid});
    % plot3(xData(:,1), xData(:,2), yData, 'ro');
    % surface(slip, FZ, out);
    % xlabel('SA (deg)'); ylabel('FZ (N)'); 
    % 
    % if Mode == "FY"
    %     zlabel('FY (N)');
    % elseif Mode == "MX"
    %     zlabel('MX (Nm)');
    % elseif Mode == "MZ"
    %     zlabel('MZ (Nm)');
    % end
    % 
    % box on; grid minor; view(-30, 45);

end

