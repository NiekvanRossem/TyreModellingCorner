%%-----------------------------------------------------------------------%%
% filename:         IdentifySweep.m
% author(s):        Niek van Rossem
% Creation date:    17-09-2024
%%-----------------------------------------------------------------------%%

function [z_new, Figures] = IdentifySweep(data, Figures, Settings)

    % cornering data
    if data.testid == "Cornering"

        % fit spline to slip angle channel
        sp = spline(data.IDX, data.SA);

        % find zero crossings
        z = fnzeros(sp);
        z = round(z(1,:));
    
        % add the first and last data point
        z = horzcat(data.IDX(1), z, data.IDX(end));
    
        z_new = [];
    
        for n = 1:length(z)
            if mod(n,2) == 1
                temp = z(n);
                z_new = horzcat(z_new, temp);
            end
        end

    if Settings.PlotFigs == 1
        figure(Figures.RawCond);
        subplot(4,1,1);
        plot(z_new, zeros(length(z_new,1)), 'r*');
    end

    % drive/brake/combined data
    elseif data.testid == "Drive/Brake/Combined1"

        % fit spline to FZ channel
        sp = spline(data.IDX, data.FZ);

        % find and resample derivative
        sp_der = fnder(sp, 1);
        sp_der_vals = fnval(sp_der, data.IDX);

        % find spikes in the derivative (indicating a change in Fz)
        idx = find(sp_der_vals < -75 | sp_der_vals > 75);

        z_new = [];
        z_new = [z_new, data.IDX(1)];

        % only use values with sufficient datapoints between them
        for n = 1:numel(idx)
            if idx(n)-z_new(end) > 600 && idx(n)-z_new(end) <= 1000

                % add to array
                z_new = [z_new, idx(n)];
                
            elseif idx(n)-z_new(end) > 1000
                
                % calculate halfway point
                hwp = round(z_new(end)+0.5*(idx(n)-z_new(end)));

                % add all to array
                z_new = [z_new, hwp, idx(n)];

            end
        end

        z_new = [z_new, data.IDX(end)];

        if Settings.PlotFigs == 1
            figure(Figures.RawCond);
            subplot(4,1,2);
            plot(z_new, zeros(length(z_new),1), 'r*');
        end

    elseif data.testid == "Drive/Brake/Combined"

        % fit spline to slip angle channel
        sp = csaps(data.IDX, data.SL, 1-1e-5);

        % find zero crossings
        zeros = fnzeros(sp);
        zeros = round(zeros(1,:));
        zeros = [data.IDX(1), zeros, data.IDX(end)];

        z_new = [];

        % there should be a single peak between two zero crossings
        for i = 1:length(zeros)-1

            temp = data.SL(zeros(i):zeros(i+1));
            
            % find peak and its location
            [~, loc] = max(abs(temp));

            temp2 = loc + data.IDX(zeros(i)) - 1;

            if temp(loc) > 0.1
                z_new = [z_new, temp2];
            end
        end

        if Settings.PlotFigs == 1
            figure(Figures.RawCond);
            subplot(4,1,2);
            xline(z_new, 'r-', 'LineWidth', 0.5);
        end
    else
        disp("Data processing for this type not yet implemented.");
    end
end

