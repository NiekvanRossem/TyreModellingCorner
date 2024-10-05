%%-----------------------------------------------------------------------%%
% filename:         PACE5_Comparison.m
% author(s):        Niek van Rossem
% Creation date:    22-09-2024
%%-----------------------------------------------------------------------%%

function [] = PACE5_Comparison(CleanData, xData, yData, Params, Mode, Tyre, Settings)
    %% Documentation
    % This function compares a fit of the PACE5 tyre model to the cleaned
    % up original data. It creates 2 figures: the first one plots the
    % curves for all the unique vertical loads in the dataset, and the 2nd
    % figure plots the surface of the fit with the cleaned data points
    % overlayed.
    %
    % INPUTS
    % ======
    % CleanData: Structure
    %   Structure with the cleaned (downsampled) data stored in arrays, as 
    %   well as the ID of the tyre and test. For this function the
    %   following channels must be present:
    %       source: string containing the name of the test facility, as
    %       well as the test round.
    %       tireid: string containing the specific tyre evaluated, as well
    %       as the rim with used.
    % xData: Nx2 array
    %   Array with the dependent (input) data.
    %       xData(:,1) = S  -> Slip ratio or angle
    %       xData(:,2) = Fz -> Vertival load
    % yData: Nx1 array
    %   Array with the independent (output) data. Either Fx, Fy, Mx, or Mz.
    % Params: Array 
    %   Array with length 5 or 6, containing the fitted coefficients.
    %   P(1) = D1 -> Peak factor
    %   P(2) = D2 -> Peak factor load sensitivity
    %   P(3) = B  -> Stiffness factor
    %   P(4) = C  -> Curvature factor
    %   P(5) = Bp -> Curvature factor load sensitivity
    %   P(6) = Sv -> OPTIONAL, this is the vertical offset
    % Mode: String
    %   String containing the name of the output variable. Either FX, FY,
    %   MX, or MZ.
    %   Structure containing the settings for the fitting / evaluation
    %   process. For this function the only relevant settings are the ones
    %   used in the Pacejka5_model.m function:
    %       AngleUnit: string containing the unit used for the angle (deg
    %       or rad).
    %
    % OUTPUTS
    % =======
    % none.

    %% Compare fit to original data (curve plots)
    
    % find vertical loads
    verticalLoad = unique(xData(:,2));
        
    figtitle1 = CleanData.source;
    figtitle2 = CleanData.tireid;
    figtitle3 = char(' | ' + Mode + ' Fit (' + Tyre.Model + ') | Camber = ' + num2str(round(Tyre.Camber, 1)) + ' deg | Pressure = ' + num2str(round(Tyre.Pressure, 2)) + ' bar');

    % set figure formatting
    figure('Name', 'Curve comparison'); hold all;
    title({figtitle1, [figtitle2, figtitle3]});
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
    elseif Mode == "FX"
        xlabel('SL');
        ylabel('FX (N)');
    end

    % create slip angle/ratio array
    if CleanData.testid == "Cornering"
        slip = linspace(-15, 15, 100)';
    elseif CleanData.testid == "Drive/Brake/Combined"
        slip = linspace(-0.25, 0.25, 100)';
    end

    xline(0, 'k'); yline(0, 'k');
    
    % loop over all vertical loads
    for n = 1:numel(unique(xData(:,2)))
        
        % find indices
        idx = find(xData(:,2) == verticalLoad(n));
        
        % calculate Fy from fit
        out = Pacejka5_model(Params, [slip, verticalLoad(n)*ones(size(slip))], Settings);
    
        % plot data and fit
        plot(xData(idx,1), yData(idx), 'ro');
        plot(slip, out, 'b-');
    end
    
    %% Compare fit to original data (surface plot)
    
    % create dependent variable grid
    FZ = linspace(0, 2500, 100); 
    % slip = linspace(-15, 15, 100);
    [slip, FZ] = meshgrid(slip, FZ);
     
    % convert to input array
    FZ = reshape(FZ, 100*100, []);
    slip = reshape(slip, 100*100, []);
    X = [slip, FZ];
    
    % calculate Fy
    out = Pacejka5_model(Params, X, Settings);
    
    % reshape for plotting
    slip = reshape(slip, 100, []);
    FZ = reshape(FZ, 100, []);
    out = reshape(out, 100, []);
    
    % plot results
    figure('Name', 'Surface plot comparison'); clf; hold all;
    title({figtitle1, [figtitle2, figtitle3]});
    plot3(xData(:,1), xData(:,2), yData, 'ro');
    surface(slip, FZ, out);
    xlabel('SA (deg)'); ylabel('FZ (N)'); 
    
    % set z-label
    if Mode == "FY"
        zlabel('FY (N)');
    elseif Mode == "MX"
        zlabel('MX (Nm)');
    elseif Mode == "MZ"
        zlabel('MZ (Nm)');
    elseif Mode == "FX"
        zlabel("FX (N)");
    end
    
    box on; grid minor; view(-30, 45);

end

