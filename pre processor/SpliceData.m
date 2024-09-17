function [CleanData] = SpliceData(RawData, Settings)
    % initialise new index vector
    q = 0;
    
    % loop over every sweep
    for n = 1:length(z)-3
        if mod(n,2) == 0
        
            % select subset of data
            sa = RawData.SA(z(n+1):z(n+3)-3);
            fx = RawData.FX(z(n+1):z(n+3)-3);
            fy = RawData.FY(z(n+1):z(n+3)-3);
            fz = RawData.FZ(z(n+1):z(n+3)-3);
            mz = RawData.MZ(z(n+1):z(n+3)-3);
            mx = RawData.MX(z(n+1):z(n+3)-3);
            rl = RawData.RL(z(n+1):z(n+3)-3);
            ia = RawData.IA(z(n+1):z(n+3)-3);
            p  = RawData.P(z(n+1):z(n+3)-3);
        
            % calculate average camber and pressure
            ia_avg = round(mean(ia), 3);
            p_avg  = round(mean(p), 3);
            fz_avg = round(mean(fz), 0);

            % fit a smoothed spline to the channels
            sp_fy = csaps(sa, fy, Settings.Smoothing);
            sp_mx = csaps(sa, mx, Settings.Smoothing);
            sp_mz = csaps(sa, mz, Settings.Smoothing);
            sp_rl = csaps(sa, rl, Settings.Smoothing);
        
            % plot one of the segments to check
            if isequal(n, 14) & Settings.PlotFigs == 1
                figtitle1 = Tyre.Brand + " " + Tyre.Item + " " + Tyre.Dimensions + " (" + Tyre.Compound + " compound) on " + Tyre.RimWidth + " rim";
                figtitle2 = "Camber = " + num2str(round(ia_avg, 1)) + " deg | pressure = " + num2str(round(p_avg, 2)) + " bar | Fz = " + num2str(round(mean(fz), 0)) + " N";
                figure('Name', figtitle2);
                
                sgtitle({figtitle1, figtitle2});
                subplot(3,1,1); hold on; grid on;
                    plot(sa, fy, 'b.');
                    fnplt(sp_fy, 'r-');
                    xlabel('slip angle (deg)');
                    ylabel('side force (N)');
                subplot(3,1,2); hold on; grid on;
                    plot(sa, mx, 'b.');
                    fnplt(sp_mx, 'r-');
                    xlabel('slip angle (deg)');
                    ylabel('overturning moment (Nm)');
                subplot(3,1,3); hold on; grid on;
                    plot(sa, mz, 'b.');
                    fnplt(sp_mz, 'r-');
                    xlabel('slip angle (deg)');
                    ylabel('self-aligning moment (Nm)');
        
                figure;
                    sgtitle({figtitle1, figtitle2});
                    plot3(fz, sa, fy, '.', 'MarkerSize', 1); 
                    hold on; grid on;
                    xlabel('Vertical load (N)');
                    ylabel('Slip angle (deg)');
                    zlabel('Side force (N)');
            end
        
            % store smoothed data in new table
            for sl = 1+floor(min(sa)):Settings.StepSize:ceil(max(sa))-1
                q = q + 1;
                CleanData(q, 1) = q;
                CleanData(q, 2) = sl;
                CleanData(q, 3) = 2*round(mean(0.5*ia), 0);
                CleanData(q, 4) = 20*round(mean(0.05*p), 2 , 'Significant');
                CleanData(q, 5) = fz_avg;
                CleanData(q, 6) = fnval(sp_fy, sl);
                CleanData(q, 7) = fnval(sp_mx, sl);
                CleanData(q, 8) = fnval(sp_mz, sl);
        
            end

            VariableNames = ["N", "SA", "IA", "P", "FZ", "FY", "MX", "MZ"];
            CleanData = array2table(CleanData, "VariableNames", VariableNames);
        end
    end

