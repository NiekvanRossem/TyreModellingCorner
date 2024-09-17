function [data, Tyre, FigName] = LoadTyreDataTransient(Round, Run, BreakIn, PlotFigs)
    
    filename = "TyreData-Processing\database\Round" + num2str(Round) + "Database.csv";

    % load database table for respective round
    database = readtable(filename);
    
    if Round == 8
        RunCode = "\A1965run";
    elseif Round == 9
        RunCode = "\B2356run";
    else
        disp('Round no. invalid or not yet implemented');
    end

    filename = "Tyre stuff\TTC data\Round " + num2str(Round) + "\RunData_Cornering_Matlab_SI_Round" + num2str(Round) + RunCode + num2str(Run) + ".mat";

    % Hoosier 16x7.5-R10 (R20 compound) Lateral tests from round 9
    load(filename);
    
    % create data table
    data = table( ...
        AMBTMP, ...
        ET, ...
        FX, ...
        FY, ...
        FZ, ...
        IA, ...
        MX, ...
        MZ, ...
        N, ...
        NFX, ...
        NFY, ...
        P, ...
        RE, ...
        RL, ...
        RST, ...
        RUN, ...
        SA, ...
        SL, ...
        SR, ...
        TSTC, ...
        TSTI, ...
        TSTO, ...
        V);
    
    % invert loads for proper axis system
    data.FZ = -data.FZ;
    data.FY = -data.FY;
    
    % convert pressure from bar to bar
    data.P = data.P/1e2;
    
    % convert velocity from km/h to m/s
    data.V = data.V/3.6;

    % convert loaded radius from cm to m
    data.RL = data.RL/1e2;

    % fit spline to velocity over time channel
    v_sp = csaps(data.ET, data.V, 0.999);
    
    % create distance spline
    d_sp = fnint(v_sp);
    
    % create distance channel
    for n = 1:length(data.ET)
        data.D(n) = fnval(d_sp, data.ET(n));
    end

    % create index vector
    data.N = linspace(1, length(data.SA), length(data.SA))';
    
    % remove break-in procedure (select range manually)
    range = 1:BreakIn;
    data(range, :) = [];
    
    % metadata (fill these in manually)
    index = find(database.Run == Run);
    Tyre.Brand      = string(database.Brand(index));
    Tyre.Compound   = string(database.Compound(index));
    Tyre.Dimensions = string(database.Dimensions(index));
    Tyre.Item       = string(database.Item(index));
    Tyre.DataOrigin = string(database.DataOrigin(index));
    Tyre.Run        = string(database.Run_1(index));
    Tyre.RimWidth   = string(database.RimWidth(index));
    
    % Plot raw data
    if PlotFigs == 1
        FigName = figure("Name", "Full dataset");
        figtitle1 = "Full TTC dataset | " + Tyre.DataOrigin + " (" + Tyre.Run + ")";
        figtitle2 = Tyre.Brand + " " + Tyre.Item + " " + Tyre.Dimensions + " (" + Tyre.Compound + " compound) on " + Tyre.RimWidth + " rim";
        sgtitle({figtitle1, figtitle2});
        subplot(7,1,1);
            plot(data.N, data.SA, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Slip angle (deg)");
        subplot(7,1,2);
            plot(data.N, data.FZ, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Vertical load (N)");
        subplot(7,1,3);
            plot(data.N, data.P, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Pressure (bar)");
        subplot(7,1,4);
            plot(data.N, data.V, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Veloctity (m/s)");
        subplot(7,1,5);
            plot(data.N, data.FY, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Side force (N)");
        subplot(7,1,6);
            plot(data.N, data.MZ, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Self-aligning moment (N)");
        subplot(7,1,7);
            plot(data.N, data.D, '.', 'MarkerSize', 1); hold on;
            xlim([data.N(1) data.N(end)]);
            title("Distance (m)");
    end
end
