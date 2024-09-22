function [] = PACE5_Comparison(CleanData, xData, yData, Params, Mode)

    %% Compare fit to original data (curve plot)
    
    % find vertical loads
    verticalLoad = unique(xData(:,2));
        
    % set figure formatting
    figure('Name', 'Curve comparison'); hold all;
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
    slip = linspace(-15, 15, 100)';
    xline(0, 'k'); yline(0, 'k');
    
    % loop over all vertical loads
    for n = 1:numel(unique(xData(:,2)))
        
        % find indices
        idx = find(xData(:,2) == verticalLoad(n));
        
        % calculate Fy from fit
        out = Pacejka5_model(Params, [slip, verticalLoad(n)*ones(size(slip))]);
    
        % plot data and fit
        plot(xData(idx,1), yData(idx), 'ro');
        plot(slip, out, 'b-');
    end
    
    %% Compare fit to original data (surface plot)
    
    % create dependent variable grid
    FZ = linspace(0, 2500, 100); 
    slip = linspace(-15, 15, 100);
    [slip, FZ] = meshgrid(slip, FZ);
     
    % convert to input array
    FZ = reshape(FZ, 100*100, []);
    slip = reshape(slip, 100*100, []);
    X = [slip, FZ];
    
    % calculate Fy
    out = Pacejka5_model(Params, X);
    
    % reshape for plotting
    slip = reshape(slip, 100, []);
    FZ = reshape(FZ, 100, []);
    out = reshape(out, 100, []);
    
    % plot results
    figure('Name', 'Surface plot comparison'); clf; hold all;
    title({CleanData.source, CleanData.tireid});
    plot3(xData(:,1), xData(:,2), yData, 'r.');
    surface(slip, FZ, out);
    xlabel('SA (deg)'); ylabel('FZ (N)'); zlabel('FY (N)');
    box on; grid minor; view(-30, 45);

end

