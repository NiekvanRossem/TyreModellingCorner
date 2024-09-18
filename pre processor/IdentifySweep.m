function [z_new, Figures] = IdentifySweep(data, Figures, Settings)

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

    % add to plot
    if Settings.PlotFigs == 1
        figure(Figures.RawCond);
            for n = 1:4
                subplot(4,1,n);
                xline(z_new, 'r-', 'LineWidth', 0.5);
            end
        figure(Figures.RawForces);
            for n = 1:4
                subplot(4,1,n);
                xline(z_new, 'r-', 'LineWidth', 0.5);
            end
        figure(Figures.RawMoments);
            if data.testid == "Cornering"
                figsize = 4;
            else
                figsize = 3;
            end
            for n = 1:figsize
                subplot(4,1,n);
                xline(z_new, 'r-', 'LineWidth', 0.5);
            end
        figure(Figures.RawTemps);
            for n = 1:6
                subplot(6,1,n);
                xline(z_new, 'r-', 'LineWidth', 0.5);
            end
        figure(Figures.RawOther);
            for n = 1:5
                subplot(5,1,n);
                xline(z_new, 'r-', 'LineWidth', 0.5);
            end

    end

end

