%%-----------------------------------------------------------------------%%
% filename:         SpliceData.m
% author(s):        Niek van Rossem
% Creation date:    17-09-2024
%%-----------------------------------------------------------------------%%

function [CleanData, RawData, SummaryData, Figures] = SpliceData(RawData, Settings, Figures, z)

    % initialise new index vector
    q = 0;

    % select subset of data corresponding to single sweep
    fn = RawData.channel.name;
        
    % loop over every sweep
    for i = 1:length(z) - 1
    
        % extract data for single sweep
        for j = 1:numel(fn)
            NewData.(fn{j}) = RawData.(fn{j})(z(i):z(i+1));
        end

        %% Cornering data analysis
        % ambtmp    % done
        % et        % not needed
        % fx        % done
        % fy        % done
        % fz        % done
        % ia        % done
        % mx        % done
        % mz        % done
        % n         % done
        % p         % done
        % re        % not needed
        % rl        % done
        % rst       % done
        % SA        % done
        % sl        % done
        % tstc      % not needed
        % tsti      % not needed
        % tsto      % not needed
        % v         % done
        % d         % not needed
        
        % post processing for cornering
        if RawData.testid == "Cornering" && max(NewData.SA) > 1  % filter out sweeps where nothing happens

            % calculate average of variables held constant
            ambtmp_avg = round(mean(NewData.AMBTMP), 1);                    % ambient temperature
            fz_avg = 10*round(mean(0.1*NewData.FZ), 0);                     % vertical load
            ia_avg = 2*round(mean(0.5*NewData.IA), 0);                      % inclination angle
            n_avg  = 2*round(mean(0.5*NewData.N),0);                        % angular speed
            p_avg  = 20*round(mean(0.05*NewData.P), 2 , 'Significant');     % pressure
            sl_avg = round(mean(NewData.SL),0);                             % slip ratio
            v_avg  = round(mean(NewData.V),1);                              % velocity
            
            % clean up channels that were supposed to be constant
            RawData.AMBTMP(z(i):z(i+1)) = ambtmp_avg;                       % inclination angle
            RawData.IA(z(i):z(i+1)) = ia_avg;                               % inclination angle
            RawData.FZ(z(i):z(i+1)) = fz_avg;                               % vertical load
            RawData.N(z(i):z(i+1))  = n_avg;                                % angular speed
            RawData.P(z(i):z(i+1))  = p_avg;                                % pressure
            RawData.SL(z(i):z(i+1)) = sl_avg;                               % slip ratio
            RawData.V(z(i):z(i+1))  = v_avg;                                % velocity

            % fit a smoothed spline to the channels that vary
            sp_fx   = csaps(NewData.SA, NewData.FX, Settings.LatSmoothing);
            sp_fy   = csaps(NewData.SA, NewData.FY, Settings.LatSmoothing);
            sp_mx   = csaps(NewData.SA, NewData.MX, Settings.LatSmoothing);
            sp_mz   = csaps(NewData.SA, NewData.MZ, Settings.LatSmoothing);
            sp_rl   = csaps(NewData.SA, NewData.RL, Settings.LatSmoothing);
            sp_rst  = csaps(NewData.SA, NewData.RST, Settings.LatSmoothing);
            sp_tstc = csaps(NewData.SA, NewData.TSTC, Settings.LatSmoothing);
            sp_tsti = csaps(NewData.SA, NewData.TSTI, Settings.LatSmoothing);
            sp_tsto = csaps(NewData.SA, NewData.TSTO, Settings.LatSmoothing);

            %% plot one of the segments to check
            if isequal(i, 2)
                figtitle1 = [RawData.source, ' (run ', num2str(RawData.RUN(1)), ')'];
                figtitle2 = [RawData.tireid, ' | ', RawData.testid, ' | Camber = ', num2str(ia_avg), ' deg | pressure = ', num2str(p_avg), ' bar | Fz = ', num2str(fz_avg), ' N'];
                
                Figures.CleanDataCond = figure('Name', 'Data cleaning - test segment');
                sgtitle({figtitle1, figtitle2});
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
            end
        
            %% store smoothed data in new structure
            for j = 1+floor(min(NewData.SA)):Settings.StepSize:ceil(max(NewData.SA))-1
                q = q + 1;
                CleanData.IDX(q)    = q;
                CleanData.SA(q)     = j;
                CleanData.SL(q)     = sl_avg;
                CleanData.IA(q)     = ia_avg;
                CleanData.P(q)      = p_avg;
                CleanData.FX(q)     = fnval(sp_fx, j);
                CleanData.FY(q)     = fnval(sp_fy, j);
                CleanData.FZ(q)     = fz_avg;
                CleanData.MX(q)     = fnval(sp_mx, j);
                CleanData.MZ(q)     = fnval(sp_mz, j);
                CleanData.N(q)      = n_avg;
                CleanData.RL(q)     = fnval(sp_rl, j);
                CleanData.RST(q)    = fnval(sp_rst, j);
                CleanData.TSTC(q)   = fnval(sp_tstc, j);
                CleanData.TSTI(q)   = fnval(sp_tsti, j);
                CleanData.TSTO(q)   = fnval(sp_tsto, j);
                CleanData.V(q)      = v_avg;
            end

            %% create summary data structure
            
            % evaluation vector
            eval = 1+floor(min(NewData.SA)):0.01:ceil(max(NewData.SA))-1;
    
            % find min and max side force
            fy_max = max(fnval(sp_fy, eval));
            fy_min = min(fnval(sp_fy, eval));

            % create summary data structure
            SummaryData.MUY1(i) = fy_max(1)/fz_avg;
            SummaryData.MUY2(i) = fy_min(1)/fz_avg;
            SummaryData.P(i)    = p_avg;
            SummaryData.IA(i)   = ia_avg;
            SummaryData.FZ(i)   = fz_avg;

        end

        if RawData.testid == "Drive/Brake/Combined" && min(NewData.SL) < 0.1 && max(NewData.SL) > 0.1
                        
            % calculate average of variables held constant
            ambtmp_avg = round(mean(NewData.AMBTMP), 1);                    % ambient temperature
            fz_avg = 10*round(mean(0.1*NewData.FZ), 0);                     % vertical load
            ia_avg = 2*round(mean(0.5*NewData.IA), 0);                      % inclination angle
            n_avg  = 2*round(mean(0.5*NewData.N),0);                        % angular speed
            p_avg  = 20*round(mean(0.05*NewData.P), 2 , 'Significant');     % pressure
            sa_avg = round(mean(NewData.SA),1);                             % slip angle
            v_avg  = round(mean(NewData.V),1);                              % velocity

            % find standard deviation of fz for outlier detection
            fz_std = std(NewData.FZ);

            idx = find(abs(NewData.FZ - fz_avg) < fz_std);

            % extract data for single sweep
            for j = 1:numel(fn)
                NewData.(fn{j}) = NewData.(fn{j})(idx);
            end

            % clean up channels that were supposed to be constant
            %RawData.AMBTMP(z(i):z(i+1)) = ambtmp_avg;                       % inclination angle
            %RawData.IA(z(i):z(i+1)) = ia_avg;                               % inclination angle
            %RawData.FZ(z(i):z(i+1)) = fz_avg;                               % vertical load
            %RawData.N(z(i):z(i+1))  = n_avg;                                % angular speed
            %RawData.P(z(i):z(i+1))  = p_avg;                                % pressure
            %RawData.SA(z(i):z(i+1)) = sa_avg;                               % slip angle
            %RawData.V(z(i):z(i+1))  = v_avg;                                % velocity

            % fit a smoothed spline to the channels that vary
            sp_fx   = csaps(NewData.SL, NewData.FX, Settings.LongSmoothing);
            sp_fy   = csaps(NewData.SL, NewData.FY, Settings.LongSmoothing);
            sp_mx   = csaps(NewData.SL, NewData.MX, Settings.LongSmoothing);
            sp_mz   = csaps(NewData.SL, NewData.MZ, Settings.LongSmoothing);
            sp_rl   = csaps(NewData.SL, NewData.RL, Settings.LongSmoothing);
            sp_rst  = csaps(NewData.SL, NewData.RST, Settings.LongSmoothing);
            sp_tstc = csaps(NewData.SL, NewData.TSTC, Settings.LongSmoothing);
            sp_tsti = csaps(NewData.SL, NewData.TSTI, Settings.LongSmoothing);
            sp_tsto = csaps(NewData.SL, NewData.TSTO, Settings.LongSmoothing);

            %% plot one of the segments to check
            if isequal(i, 2)
                figtitle1 = [RawData.source, ' (run ', num2str(RawData.RUN(1)), ')'];
                figtitle2 = [RawData.tireid, ' | ', RawData.testid, ' | Camber = ', num2str(ia_avg), ' deg | pressure = ', num2str(p_avg), ' bar | Fz = ', num2str(fz_avg), ' N'];
                
                figure('Name', 'Data cleaning - test segment');
                sgtitle({figtitle1, figtitle2});
                plot(NewData.SL, NewData.FX, 'b.');
                fnplt(sp_fx, 'r-');
                xlabel('slip angle (deg)');
                ylabel('side force (N)');
            end
            
            %% store smoothed data in new structure
            for j = 0.01*floor(100*min(NewData.SL)):0.01*Settings.StepSize:0.01*ceil(100*max(NewData.SL))
                q = q + 1;
                CleanData.IDX(q)    = q;
                CleanData.SA(q)     = sa_avg;
                CleanData.SL(q)     = j;
                CleanData.IA(q)     = ia_avg;
                CleanData.P(q)      = p_avg;
                CleanData.FX(q)     = fnval(sp_fx, j);
                CleanData.FY(q)     = fnval(sp_fy, j);
                CleanData.FZ(q)     = fz_avg;
                CleanData.MX(q)     = fnval(sp_mx, j);
                CleanData.MZ(q)     = fnval(sp_mz, j);
                CleanData.N(q)      = n_avg;
                CleanData.RL(q)     = fnval(sp_rl, j);
                CleanData.RST(q)    = fnval(sp_rst, j);
                CleanData.TSTC(q)   = fnval(sp_tstc, j);
                CleanData.TSTI(q)   = fnval(sp_tsti, j);
                CleanData.TSTO(q)   = fnval(sp_tsto, j);
                CleanData.V(q)      = v_avg;
            end

            %% create summary data structure
            
            if sa_avg > -0.5 && sa_avg < 0.5
                
                % evaluation vector
                eval = 0.01*floor(100*min(NewData.SL)):0.01*Settings.StepSize:0.01*ceil(100*max(NewData.SL));
        
                % find min and max side force
                fx_max = max(fnval(sp_fx, eval));
                fx_min = min(fnval(sp_fx, eval));
    
                % create summary data structure
                SummaryData.MUX1(i) = fx_max(1)/fz_avg;
                SummaryData.MUX2(i) = fx_min(1)/fz_avg;
                SummaryData.P(i)    = p_avg;
                SummaryData.IA(i)   = ia_avg;
                SummaryData.FZ(i)   = fz_avg;
            
            end
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

