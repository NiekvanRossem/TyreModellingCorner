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

        x_new = zeros(size(z_new));

        if Settings.PlotFigs == 1
            figure(Figures.RawCond);
            subplot(4,1,1);
            plot(z_new, x_new, 'r*');
        end

    elseif data.testid == "Drive/Brake/Combined"

        % fit spline to slip angle channel
        sp = csaps(data.IDX, data.SL, 1-1e-5);

        % find zero crossings
        z = fnzeros(sp);
        z = round(z(1,:));
        z = [data.IDX(1), z, data.IDX(end)];

        z_new = [];

        % there should be a single peak between two zero crossings
        for i = 1:length(z)-1

            temp = data.SL(z(i):z(i+1));
            
            % find peak and its location
            [~, loc] = max(abs(temp));

            temp2 = loc + data.IDX(z(i)) - 1;

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

