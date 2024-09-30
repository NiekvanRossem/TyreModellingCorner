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

    % drive/brake/combined data
    elseif data.testid == "Drive/Brake/Combined"

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
    else
        disp("Data processing for this type not yet implemented.");
    end
    
    % add to plot
    if Settings.PlotFigs == 1
        figure(Figures.RawCond);
        subplot(4,1,1);
        xline(z_new, 'r-', 'LineWidth', 0.5);
    end

end

