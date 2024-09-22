function [CleanData, RawData, SummaryData, Figures] = SpliceData(RawData, Settings, Figures, z)

    % initialise new index vector
    q = 0;
    
    % loop over every sweep
    for i = 1:length(z) - 1
    
        % select subset of data corresponding to single sweep
        fn = RawData.channel.name;
        
        % extract data for single sweep
        for j = 1:numel(fn)
            NewData.(fn{j}) = RawData.(fn{j})(z(i):z(i+1));
        end

        % ambtmp  = RawData.AMBTMP(z(i):z(i+1));  %
        % et      = RawData.ET(z(i):z(i+1));      %
        % fx      = RawData.FX(z(i):z(i+1));      %
        % fy      = RawData.FY(z(i):z(i+1));      % done
        % fz      = RawData.FZ(z(i):z(i+1));      % done
        % ia      = RawData.IA(z(i):z(i+1));      % done
        % mx      = RawData.MX(z(i):z(i+1));      % done
        % my      = RawData.MY(z(i):z(i+1));      %
        % mz      = RawData.MZ(z(i):z(i+1));      % done
        % n       = RawData.N(z(i):z(i+1));       %
        % p       = RawData.P(z(i):z(i+1));       % done
        % re      = RawData.RE(z(i):z(i+1));      %
        % rl      = RawData.RL(z(i):z(i+1));      %
        % rst     = RawData.RST(z(i):z(i+1));     %
        % SA      = RawData.SA(z(i):z(i+1));      % done
        % sl      = RawData.SL(z(i):z(i+1));      %
        % tstc    = RawData.TSTC(z(i):z(i+1));    %
        % tsti    = RawData.TSTI(z(i):z(i+1));    %
        % tsto    = RawData.TSTO(z(i):z(i+1));    %
        % v       = RawData.V(z(i):z(i+1));       %
        % d       = RawData.D(z(i):z(i+1));       %
        
        if max(NewData.SA) > 1  % filter out sweeps where nothing happens

            % calculate average of variables held constant
            ia_avg = 2*round(mean(0.5*NewData.IA), 0);                      % inclination angle
            p_avg  = 20*round(mean(0.05*NewData.P), 2 , 'Significant');     % pressure
            fz_avg = 10*round(mean(0.1*NewData.FZ), 0);                     % vertical load
            v_avg  = round(mean(NewData.V),1);                              % velocity
            
            % clean up channels that were supposed to be constant
            RawData.IA(z(i):z(i+1)) = ia_avg;                               % inclination angle
            RawData.P(z(i):z(i+1))  = p_avg;                                % pressure
            RawData.FZ(z(i):z(i+1)) = fz_avg;                               % vertical load
            RawData.V(z(i):z(i+1))  = v_avg;                                % velocity

            % fit a smoothed spline to the channels
            sp_fx = csaps(NewData.SA, NewData.FX, Settings.Smoothing);
            sp_fy = csaps(NewData.SA, NewData.FY, Settings.Smoothing);
            sp_mx = csaps(NewData.SA, NewData.MX, Settings.Smoothing);
    
            sp_mz = csaps(NewData.SA, NewData.MZ, Settings.Smoothing);
            %sp_rl = csaps(sa, rl, Settings.Smoothing);
        
            %% plot one of the segments to check
            if isequal(i, 2) %& Settings.PlotFigs == 1
                figtitle1 = [RawData.source, ' (run ', num2str(RawData.RUN(1)), ')'];
                figtitle2 = [RawData.tireid, ' | ', RawData.testid, ' | Camber = ', num2str(ia_avg), ' deg | pressure = ', num2str(p_avg), ' bar | Fz = ', num2str(fz_avg), ' N'];
                
                Figures.CleanDataCond = figure('Name', 'Data cleaning - test segment');
                    sgtitle({figtitle1, figtitle2});
                    if RawData.testid == "Cornering"
                        subplot(1,3,1); hold on; grid on;
                            plot(NewData.SA, NewData.FY, 'b.');
                            fnplt(sp_fy, 'r-');
                            xlabel('SA (deg)');
                            ylabel('FY (N)');
                        subplot(1,3,2); hold on; grid on;
                            plot(NewData.SA, NewData.MX, 'b.');
                            fnplt(sp_mx, 'r-');
                            xlabel('SA (deg)');
                            ylabel('MX (Nm)');
                        subplot(1,3,3); hold on; grid on;
                            plot(NewData.SA, NewData.MZ, 'b.');
                            fnplt(sp_mz, 'r-');
                            xlabel('SA (deg)');
                            ylabel('MZ (Nm)');
                    else
                        subplot(1,3,1); hold on; grid on;
                            plot(NewData.SL, NewData.FX, 'b.');
                            fnplt(sp_fx, 'r-');
                            xlabel('slip angle (deg)');
                            ylabel('side force (N)');
                        subplot(1,3,2); hold on; grid on;
                            plot(NewData.SL, NewData.MX, 'b.');
                            fnplt(sp_mx, 'r-');
                            xlabel('slip angle (deg)');
                            ylabel('overturning moment (Nm)');
                        subplot(1,3,3); hold on; grid on;
                            plot(NewData.SL, NewData.MZ, 'b.');
                            fnplt(sp_mz, 'r-');
                            xlabel('slip angle (deg)');
                            ylabel('self-aligning moment (Nm)');
                    end
            end
        
            %% store smoothed data in new structure
            for j = 1+floor(min(NewData.SA)):Settings.StepSize:ceil(max(NewData.SA))-1
                q = q + 1;
                CleanData.IDX(q) = q;
                CleanData.SA(q) = j;
                %CleanData.SL(q) = j;
                CleanData.IA(q) = ia_avg;
                CleanData.P(q)  = p_avg;
                CleanData.FX(q) = fnval(sp_fx, j);
                CleanData.FY(q) = fnval(sp_fy, j);
                CleanData.FZ(q) = fz_avg;
                CleanData.MX(q) = fnval(sp_mx, j);
                %CleanData.MY(q) = fnval(sp_my, j);
                CleanData.MZ(q) = fnval(sp_mz, j);
                CleanData.V(q)  = v_avg;
            end

            %% create summary data structure
            
            % evaluation vector
            eval = 1+floor(min(NewData.SA)):Settings.StepSize:ceil(max(NewData.SA))-1;
    
            % create summary data structure
            fy_max = max(fnval(sp_fy, eval));
            fy_min = min(fnval(sp_fy, eval));
            SummaryData.MUY1(i) = fy_max(1)/fz_avg;
            SummaryData.MUY2(i) = fy_min(1)/fz_avg;
            SummaryData.P(i) = p_avg;
            SummaryData.IA(i) = ia_avg;
            SummaryData.FZ(i) = fz_avg;
        end
    end

    % add metadata to cleaned data structure
    CleanData.source    = RawData.source;
    CleanData.testid    = RawData.testid;
    CleanData.tireid    = RawData.tireid;
    CleanData.channel   = RawData.channel;

    % display dataset reduction
    reduction = numel(CleanData.IDX)/numel(RawData.IDX)*100;
    disp(['Reduced dataset to ', num2str(round(reduction, 1)), '% of its original size!']);
end

