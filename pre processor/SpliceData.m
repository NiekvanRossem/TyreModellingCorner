%%-----------------------------------------------------------------------%%
% filename:         SpliceData.m
% author(s):        Niek van Rossem
% Creation date:    17-09-2024
%%-----------------------------------------------------------------------%%

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
            sp_fx   = csaps(NewData.SA, NewData.FX, Settings.Smoothing);
            sp_fy   = csaps(NewData.SA, NewData.FY, Settings.Smoothing);
            sp_mx   = csaps(NewData.SA, NewData.MX, Settings.Smoothing);
            sp_mz   = csaps(NewData.SA, NewData.MZ, Settings.Smoothing);
            sp_rl   = csaps(NewData.SA, NewData.RL, Settings.Smoothing);
            sp_rst  = csaps(NewData.SA, NewData.RST, Settings.Smoothing);
            sp_tstc = csaps(NewData.SA, NewData.TSTC, Settings.Smoothing);
            sp_tsti = csaps(NewData.SA, NewData.TSTI, Settings.Smoothing);
            sp_tsto = csaps(NewData.SA, NewData.TSTO, Settings.Smoothing);

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
                    % else
                    %     subplot(1,3,1); hold on; grid on;
                    %         plot(NewData.SL, NewData.FX, 'b.');
                    %         fnplt(sp_fx, 'r-');
                    %         xlabel('slip angle (deg)');
                    %         ylabel('side force (N)');
                    %     subplot(1,3,2); hold on; grid on;
                    %         plot(NewData.SL, NewData.MX, 'b.');
                    %         fnplt(sp_mx, 'r-');
                    %         xlabel('slip angle (deg)');
                    %         ylabel('overturning moment (Nm)');
                    %     subplot(1,3,3); hold on; grid on;
                    %         plot(NewData.SL, NewData.MZ, 'b.');
                    %         fnplt(sp_mz, 'r-');
                    %         xlabel('slip angle (deg)');
                    %         ylabel('self-aligning moment (Nm)');
                    end
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

