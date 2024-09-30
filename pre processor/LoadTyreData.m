%%-----------------------------------------------------------------------%%
% filename:         LoadTyreData.m
% author(s):        Niek van Rossem
% Creation date:    17-09-2024
%%-----------------------------------------------------------------------%%

function [data, Tyre, Figures] = LoadTyreData(Settings)
    
    Figures = [];

    % create filename for database lookup table
    filename = "database\Round" + num2str(Settings.Round) + "Database.csv";

    % load database table for respective round
    database = readtable(filename);
    
    % select part of filename corresponding to testing round
    if Settings.Round == 8
        RunCode = "B1965run";
    elseif Settings.Round == 9
        RunCode = "B2356run";
    else
        disp('Round no. invalid or not yet implemented');
    end

    % create empty data variable
    data = [];

    
    % loop over selected runs
    for i = 1:length(Settings.Run)

        % create filename for TTC datafile
        filename = RunCode + num2str(Settings.Run(i)) + ".mat";

        % load datafile
        temp = load(filename);

        % for importing multiple runs, loop over all the fields in the
        % structure, and append the extra data
        if i > 1

            % create array with fieldnames
            fn = fieldnames(data);
            fn(end-3:end) = [];
            
            % loop over all field names, and append the data
            for j = 1:numel(fn)
                data.(fn{j}) = vertcat(data.(fn{j}), temp.(fn{j}));
            end
        else
            data = temp;
        end
    end
    
    % invert certain channels for selected convention
    if Settings.Convention == "ISO_A"
        data.SA = -data.SA;
        data.FY = -data.FY;
        data.FZ = -data.FZ;
        data.MZ = -data.MZ;
    elseif Settings.Convention == "ISO_B"        
        data.FY = -data.FY;
        data.FZ = -data.FZ;
        data.MZ = -data.MZ;
    end

    % perform unit conversions
    data.P  = data.P/1e2;       % pressure from kPa to bar
    data.V  = data.V/3.6;       % velocity from kph to m/s
    data.N  = data.N*2*pi/60;   % angular velocity from rpm to rad/s
    data.RE = data.RE/1e2;      % effective radius from cm to m
    data.RL = data.RL/1e2;      % loaded radius from cm to m

    % create index channel
    data.IDX = linspace(1, length(data.SA), length(data.SA))';
    data.channel.name = [data.channel.name, "IDX"];

    % correct ET channel start time
    data.ET = data.ET - data.ET(1);

    % create distance channel by integrating the velocity channel
    data.D = zeros(size(data.ET));

    for n = 1:length(data.ET)

        % set initial distance to zero
        if n == 1
            data.D(n) = 0;

        % Trapezoidal rule for every other datapoint
        else
            data.D(n) = data.D(n-1) + ((data.ET(n) - data.ET(n-1))/2)*(data.V(n-1) + data.V(n));
        end
    end
    
    % add distance channel to names
    data.channel.name = [data.channel.name, "D"];
  
    % metadata
    index = database.Run == Settings.Run(1);
    Tyre.Brand      = string(database.Brand(index));
    Tyre.Compound   = string(database.Compound(index));
    Tyre.Dimensions = string(database.Dimensions(index));
    Tyre.Item       = string(database.Item(index));
    Tyre.DataOrigin = string(database.DataOrigin(index));
    Tyre.RimWidth   = string(database.RimWidth(index));
    
    % Plot raw data
    if Settings.PlotFigs == 1
        % create string for figure title
        figtitle1 = [data.source, ' (run ', num2str(Settings.Run), ')'];
        figtitle2 = [data.tireid, ' | ', data.testid];

        % 1st figure (operating conditions)
        Figures.RawCond = figure("Name", "Raw data - Operating conditions");
        sgtitle({figtitle1, figtitle2});
        subplot(4,1,1); hold all; grid on;
            plot(data.IDX, data.SA, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("SA (deg)");
        subplot(4,1,2); hold all; grid on;
            plot(data.IDX, data.SL, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("SL");
        subplot(4,1,3); hold all; grid on;
            plot(data.IDX, data.P, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("P (bar)");
        subplot(4,1,4); hold all; grid on;
            plot(data.IDX, data.IA, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("IA (deg)");
        
        % 2nd figure (forces)
        Figures.RawForces = figure("Name", "Raw data - Forces");
        sgtitle({figtitle1, figtitle2});
        if data.testid == "Cornering"
            subplot(4,1,1); hold all; grid on;
                plot(data.IDX, data.SA, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SA (deg)");
        else
            subplot(4,1,1); hold all; grid on;
                plot(data.IDX, data.SL, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SL");
        end
        subplot(4,1,2); hold all; grid on;
            plot(data.IDX, data.FX, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("FX (N)");
        subplot(4,1,3); hold all; grid on;
            plot(data.IDX, data.FY, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("FY (N)");
        subplot(4,1,4); hold all; grid on;
            plot(data.IDX, data.FZ, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("FZ (N)");

        % 3rd figure (moments)
        Figures.RawMoments = figure("Name", "Raw data - Moments");
        sgtitle({figtitle1, figtitle2});
        if data.testid == "Cornering"
            subplot(3,1,1); hold all; grid on;
                plot(data.IDX, data.SA, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SA (deg)");
            subplot(3,1,2); hold all; grid on;
                plot(data.IDX, data.MX, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("MX (Nm)");
            subplot(3,1,3); hold all; grid on;
                plot(data.IDX, data.MZ, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("MZ (Nm)");
        elseif data.testid == "Drive/Brake/Combined"
            subplot(3,1,1); hold all; grid on;
                plot(data.IDX, data.SL, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SL");
            subplot(3,1,2); hold all; grid on;
                plot(data.IDX, data.MX, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("MX (Nm)");
            subplot(3,1,3); hold all; grid on;
                plot(data.IDX, data.MZ, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("MZ (Nm)");
        else
            disp("Data processing for this type of run is not yet implemented.");
        end
        
        % 4th figure (temperatures)
        Figures.RawTemps = figure("Name", "Raw data - Temperatures");
        sgtitle({figtitle1, figtitle2});
        if data.testid == "Cornering"
            subplot(6,1,1); hold all; grid on;
                plot(data.IDX, data.SA, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SA (deg)");
        elseif data.testid == "Drive/Brake/Combined"
            subplot(6,1,1); hold all; grid on;
                plot(data.IDX, data.SL, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SL");
        else
            disp("Data processing for this type of run is not yet implemented.");
        end
        subplot(6,1,2); hold all; grid on;
            plot(data.IDX, data.AMBTMP, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("AMBTMP (deg C)");
        subplot(6,1,3); hold all; grid on;
            plot(data.IDX, data.RST, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("RST (deg C)");
        subplot(6,1,4); hold all; grid on;
            plot(data.IDX, data.TSTI, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("TSTI (deg C)");
        subplot(6,1,5); hold all; grid on;
            plot(data.IDX, data.TSTC, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("TSTC (deg C)");
        subplot(6,1,6); hold all; grid on;
            plot(data.IDX, data.TSTO, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("TSTO (deg C)");

        % 5th figure (miscellaneous)
        Figures.RawOther = figure("Name", "Raw data - Miscellaneous");
        sgtitle({figtitle1, figtitle2});
        if data.testid == "Cornering"
            subplot(5,1,1); hold all; grid on;
                plot(data.IDX, data.SA, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SA (deg)");
        elseif data.testid == "Drive/Brake/Combined"
            subplot(5,1,1); hold all; grid on;
                plot(data.IDX, data.SL, '.', 'MarkerSize', 1); 
                xlim([data.IDX(1) data.IDX(end)]);
                title("SL");
        else
            disp("Data processing for this type of run is not yet implemented.");
        end
        subplot(5,1,2); hold all; grid on;
            plot(data.IDX, data.N, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("N (rad/s)");
        subplot(5,1,3); hold all; grid on;
            plot(data.IDX, data.RE, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("RE (m)");
        subplot(5,1,4); hold all; grid on;
            plot(data.IDX, data.RL, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("RL (m)");
        subplot(5,1,5); hold all; grid on;
            plot(data.IDX, data.V, '.', 'MarkerSize', 1); 
            xlim([data.IDX(1) data.IDX(end)]);
            title("V (m/s)");
    end
end
