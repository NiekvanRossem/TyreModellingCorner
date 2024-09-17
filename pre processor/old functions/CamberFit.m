function [press] = CamberFit(data, PlotFigs, Limits, Tyre)

    %% Select subset of data
        
    % create index vector
    index = find( ...
        data.P  >= Limits.minpress & ...
        data.P  <= Limits.maxpress & ...
        data.FZ >= Limits.minload & ...
        data.FZ <= Limits.maxload);

    % filter data into subsets
    data_subset = data(index, :);
    
    % find tyre pressure
    press = mean(data_subset.P);

    if PlotFigs == 1
        figure;
        scatter3(data_subset.SA, data_subset.IA, data_subset.FY);
        xlabel('Slip angle');
        ylabel('Camber angle');
        zlabel('Side force');
    end
end