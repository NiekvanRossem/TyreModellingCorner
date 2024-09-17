function [new_data, output] = PreProcessDataCamber(data, Tyre, FigName, StepSize, PlotFigs)

    %% Identifying individual sweeps
    
    % fit spline to slip angle channel
    sp = spline(data.N, data.SA);
    
    % find zero crossings
    z = fnzeros(sp);
    z = round(z(1,:));
    z = horzcat(data.N(1), z, data.N(end));
    y = zeros(size(z));
    
    % add to plot
    if PlotFigs == 1
        figure(FigName);
        subplot(7,1,1);
        plot(z, y, 'r*'); hold on;
    end

    %% Splicing data into individual sweeps
    q = 0;
    
    % loop over every sweep
    for n = 4:length(z)-1
    
    
        % select subset of data
        sa = data.SA(z(n):z(n+1)-1);
        fz = data.FZ(z(n):z(n+1)-1);
        fy = data.FY(z(n):z(n+1)-1);
        mz = data.MZ(z(n):z(n+1)-1);
        mx = data.MX(z(n):z(n+1)-1);
        rl = data.RL(z(n):z(n+1)-1);
        ia = data.IA(z(n):z(n+1)-1);
        p  = data.P(z(n):z(n+1)-1);
    
        % calculate average camber and pressure
        ia_avg = round(mean(ia), 3);
        p_avg  = round(mean(p), 3);

        % fit a smoothed spline to the channels
        sp_fy = csaps(sa, fy, 0.1);
        sp_mx = csaps(sa, mx, 0.1);
        sp_mz = csaps(sa, mz, 0.1);
    
        % plot one of the segments to check
        if isequal(n, 14) & PlotFigs == 1
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
        for sl = 1+floor(min(sa)):StepSize:ceil(max(sa))-1
            q = q+1;
            
            % reflect data for negative slip angles to get negative camber
            % data
            if 1+floor(min(sa)) >= 0
                new_data(q, 1) = q;
                new_data(q, 2) = sl;
                new_data(q, 3) = 2*round(mean(0.5*ia));
                new_data(q, 4) = 10*round(mean(0.1*p), 2 , 'Significant');
                new_data(q, 5) = mean(fz);
                new_data(q, 6) = fnval(sp_fy, sl);
                new_data(q, 7) = fnval(sp_mx, sl);
                new_data(q, 8) = fnval(sp_mz, sl);
                
            elseif 1+floor(min(sa)) < 0
                new_data(q, 1) = q;
                new_data(q, 2) = -sl;
                new_data(q, 3) = -2*round(mean(0.5*ia));
                new_data(q, 4) = 10*round(mean(0.1*p), 2 , 'Significant');
                new_data(q, 5) = mean(fz);
                new_data(q, 6) = -fnval(sp_fy, sl);
                new_data(q, 7) = -fnval(sp_mx, sl);
                new_data(q, 8) = -fnval(sp_mz, sl);
                
            end
        end

        % find friction coefficient of half-sweep
        if 1+floor(min(sa)) >= 0
            output.mu(q) = max(fnval(sp_fy, 1+floor(min(sa)):StepSize:ceil(max(sa))-1))/mean(fz);
            output.rfl(q) = 0;
            output.ia(q)  = 2*round(mean(0.5*ia));
        elseif 1+floor(min(sa)) < 0
            output.mu(q) = abs(min(fnval(sp_fy, 1+floor(min(sa)):StepSize:ceil(max(sa))-1)))/mean(fz);
            output.rfl(q) = 1;
            output.ia(q)  = -2*round(mean(0.5*ia));
        end

        output.p(q) = 10*round(mean(0.1*p), 2 , 'Significant');
        output.fz(q) = mean(fz);
    end
    
    % remove empty cells
    index = find(output.mu > 0);
    output.mu   = output.mu(index);
    output.rfl  = output.rfl(index);
    output.ia   = output.ia(index);
    output.fz   = output.fz(index);
    output.p    = output.p(index);

    %% Post-process new data
    
    % sort appropriately
    new_data = sortrows(new_data, [4,3,5,2]);
    
    % convert to table
    new_data = array2table(new_data);
    
    % set header names
    new_data.Properties.VariableNames(1) = "N";
    new_data.Properties.VariableNames(2) = "SA";
    new_data.Properties.VariableNames(3) = "IA";
    new_data.Properties.VariableNames(4) = "P";
    new_data.Properties.VariableNames(5) = "FZ";
    new_data.Properties.VariableNames(6) = "FY";
    new_data.Properties.VariableNames(7) = "MX";
    new_data.Properties.VariableNames(8) = "MZ";
    
    % plot processed results
    if PlotFigs == 1
        figure("Name", "Processed dataset");
        clf;
        figtitle1 = "Processed TTC dataset | " + Tyre.DataOrigin + " (" + Tyre.Run + ")";
        figtitle2 = Tyre.Brand + " " + Tyre.Item + " " + Tyre.Dimensions + " (" + Tyre.Compound + " compound) on " + Tyre.RimWidth + " rim";
        sgtitle({figtitle1, figtitle2});
        subplot(7,1,1);
            plot(new_data.N, new_data.SA, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Slip angle (deg)');
        subplot(7,1,2);
            plot(new_data.N, new_data.FZ, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Vertical load (N)');
        subplot(7,1,3);
            plot(new_data.N, new_data.P, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Pressure (bar)');
        subplot(7,1,4);
            plot(new_data.N, new_data.IA, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Camber angle (deg)');
        subplot(7,1,5);
            plot(new_data.N, new_data.FY, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Side force (N)');
        subplot(7,1,6);
            plot(new_data.N, new_data.MZ, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Self-aligning moment (Nm)');
        subplot(7,1,7);
            plot(new_data.N, new_data.MX, '.', 'MarkerSize', 1); hold on;
            xlim([1 length(new_data.N)]);
            title('Overturning moment (Nm)');
    end
end

