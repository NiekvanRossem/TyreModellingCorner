%%-----------------------------------------------------------------------%%
% filename:         MF52_comparison.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function [] = MF52_Comparison(RawData, CleanData, xData, yData, Params, Mode, Fz0, R0, Tyre, Settings)
    %% Documentation
    %
    %

    %% Compare fit to original data (curve plots)
    
    % set figure formatting
    F1 = figure('Name', 'Curve comparison, 0 deg camber'); hold all;
        title({CleanData.source, [CleanData.tireid, ' | 0 deg camber']});
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
        xline(0, 'k'); yline(0, 'k');

    F2 = figure('Name', 'Curve comparison, 2 deg camber'); hold all;
        title({CleanData.source, [CleanData.tireid, ' | 2 deg camber']});
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
        xline(0, 'k'); yline(0, 'k');
    
    F3 = figure('Name', 'Curve comparison, 4 deg camber'); hold all;
        title({CleanData.source, [CleanData.tireid, ' | 4 deg camber']});
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
        xline(0, 'k'); yline(0, 'k');

    % set scaling factors equal to 1
    lambda.mu_y = 1;
    lambda.Cy   = 1;
    lambda.Hy   = 1;
    lambda.Vy   = 1;
    lambda.VMx  = 1;
    lambda.Mx   = 1;

    % find data for first camber angle
    if Settings.Comparison == "RawData"
    
        camberAngle  = unique(RawData.IA);
        idx1 = find(RawData.IA == camberAngle(1));
        idx2 = find(RawData.IA == camberAngle(2));
        idx3 = find(RawData.IA == camberAngle(3));
        
        newDataX1 = [RawData.SA(idx1), RawData.FZ(idx1)];        
        newDataX2 = [RawData.SA(idx2), RawData.FZ(idx2)];
        newDataX3 = [RawData.SA(idx3), RawData.FZ(idx3)];
        

        if Mode == "FY"
            newDataY1 = RawData.FY(idx1);
            newDataY2 = RawData.FY(idx2);
            newDataY3 = RawData.FY(idx3);
        elseif Mode == "MX"
            newDataY1 = RawData.MX(idx1);
            newDataY2 = RawData.MX(idx2);
            newDataY3 = RawData.MX(idx3);
        end

        % find vertical loads
        verticalLoad1 = unique(newDataX1(:,2));
        verticalLoad2 = unique(newDataX2(:,2));
        verticalLoad3 = unique(newDataX3(:,2));

    elseif Settings.Comparison == "CleanData"
        
        camberAngle  = unique(xData(:,3));
    end

    % slip angle vector
    sa = linspace(-15, 15, 100)';
    
    Params_FY = [Tyre.PCY1, Tyre.PDY1, Tyre.PDY2, Tyre.PDY3, Tyre.PEY1, Tyre.PEY2, Tyre.PEY3, Tyre.PEY4, Tyre.PKY1, Tyre.PKY2, Tyre.PKY3, Tyre.PHY1, Tyre.PHY2, Tyre.PHY3, Tyre.PVY1, Tyre.PVY2, Tyre.PVY3, Tyre.PVY4];

    % loop over all vertical loads
    for n = 1:numel(unique(newDataX1(:,2)))
        
        % find indices
        idx = find(newDataX1(:,2) == verticalLoad1(n));
        
        if Mode == "FY"

            % calculate Fy from fit
            out = MF52_FY_model(Params, [sa, verticalLoad1(n)*ones(size(sa)), camberAngle(1)*ones(size(sa))], Fz0, lambda, Settings);

        % calculate Mx from fit
        elseif Mode == "MX"

            % calculate Fy from fit
            Fy  = MF52_FY_model(Params_FY, [sa, verticalLoad1(n)*ones(size(sa)), camberAngle(1)*ones(size(sa))], Fz0, lambda, Settings);
            
            % calculate Mx from fit
            out = MF52_MX_model(Params, [Fy, verticalLoad1(n)*ones(size(sa)), camberAngle(1)*ones(size(sa))], Fz0, R0, lambda);

        end

        % plot data and fit
        figure(F1);
        plot(newDataX1(idx,1), newDataY1(idx), 'Color', '#77ac30', 'Marker', '.', 'MarkerSize', 2, 'LineStyle', 'none');
        plot(sa, out, 'b-');

    end
    
    for n = 1:numel(unique(newDataX2(:,2)))
        
        % find indices
        idx = find(newDataX2(:,2) == verticalLoad2(n));
        
        % calculate Fy from fit
        if Mode == "FY"
            out = MF52_FY_model(Params, [sa, verticalLoad2(n)*ones(size(sa)), camberAngle(2)*ones(size(sa))], Fz0, lambda, Settings);
    
        % calculate Mx from fit
        elseif Mode == "MX"
            Fy  = MF52_FY_model(Params_FY, [sa, verticalLoad2(n)*ones(size(sa)), camberAngle(2)*ones(size(sa))], Fz0, lambda, Settings);
            out = MF52_MX_model(Params, [Fy, verticalLoad2(n)*ones(size(sa)), camberAngle(2)*ones(size(sa))], Fz0, R0, lambda);
        end

        % plot data and fit
        figure(F2);
        plot(newDataX2(idx,1), newDataY2(idx), 'Color', '#77ac30', 'Marker', '.', 'MarkerSize', 2, 'LineStyle', 'none');
        plot(sa, out, 'b-');

    end

    for n = 1:numel(unique(newDataX3(:,2)))
        
        % find indices
        idx = find(newDataX3(:,2) == verticalLoad3(n));
        
        % calculate Fy from fit
        if Mode == "FY"
            out = MF52_FY_model(Params, [sa, verticalLoad3(n)*ones(size(sa)), camberAngle(3)*ones(size(sa))], Fz0, lambda, Settings);
    
        % calculate Mx from fit
        elseif Mode == "MX"

            Fy  = MF52_FY_model(Params_FY, [sa, verticalLoad3(n)*ones(size(sa)), camberAngle(3)*ones(size(sa))], Fz0, lambda, Settings);
            out = MF52_MX_model(Params, [Fy, verticalLoad3(n)*ones(size(sa)), camberAngle(3)*ones(size(sa))], Fz0, R0, lambda);

        end

        % plot data and fit
        figure(F3);
        plot(newDataX3(idx,1), newDataY3(idx), 'Color', '#77ac30', 'Marker', '.', 'MarkerSize', 2, 'LineStyle', 'none');
        plot(sa, out, 'b-');
    end

    %% Plot camber curve
    if Mode == "FY"
        FZ = 1000;
        n = 100;
        [SA, IA] = meshgrid(linspace(-15, 15, n), linspace(-5, 5, n));
    
        SA = reshape(SA, numel(SA), []);
        IA = reshape(IA, numel(IA), []);
    
        FY = MF52_FY_model(Params, [SA, FZ*ones(size(SA)), IA], Fz0, lambda, Settings);
    
        SA = reshape(SA, n, []);
        IA = reshape(IA, n, []);
        FY = reshape(FY, n, []);
    
        for i = 1:n
            idx = find(IA == IA(i));
            FY_max(i) = max(FY(idx));
    
            temp = IA(idx);
            IA_new(i) = temp(1);
    
        end
    
        figure; hold all; 
        title({[CleanData.source, ' | Camber curve'], [CleanData.tireid, ' | FZ = 1000 N | P = ', num2str(round(Tyre.Pressure, 2)), ' bar']});
        plot(IA_new, FY_max, 'b-');
        idx = find(FY_max == max(FY_max));
        plot(IA_new(idx(1)), FY_max(idx(1)), 'bo');
        xline(0, 'k-');
        xlabel('IA (deg)'); ylabel('FY (N)');
        box on; grid minor;
    
        figure; surf(SA, IA, FY);
        xlabel('SA'); ylabel('IA'); zlabel('FY')
        box on; grid minor;
    end

    %% Plot load sensitivity

    % IA = 0;
    % n = 100;
    % [SA, FZ] = meshgrid(linspace(-15, 15, n), linspace(100, 1500, n));
    % 
    % SA = reshape(SA, numel(SA), []);
    % FZ = reshape(FZ, numel(FZ), []);
    % 
    % FY = MF52_FY_model(Params, [SA, FZ, IA*ones(size(SA))], Fz0, lambda, Settings);
    % 
    % SA = reshape(SA, n, []);
    % FZ = reshape(FZ, n, []);
    % FY = reshape(FY, n, []);

    %figure; hold all;
    %surf(SA, FZ, FY);
    %xlabel('SA'); ylabel('IA'); zlabel('FY')
    %box on; grid minor;

    %% Compare fit to original data (surface plot)
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

