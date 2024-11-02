%%-----------------------------------------------------------------------%%
% filename:         MF52_FY_model.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function Mx = MF52_MX_model(P, X, Fz0, R0, lambda)
    %% Documentation
    % This function calculates the Mx based on the Magic Formula 5.2 model. 
    % This model works for all combinations of units, as long as you keep 
    % it consistent.
    %
    % INPUTS
    % ======
    % P: 3x1 matrix
    %   Set of model parameters:
    %
    % X: Nx2 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %
    % Fz0: double
    %   Nominal vertical load.

    % lambda: structure
    %   Structure containing all the scaling factors
    %
    % OUTPUTS
    % =======
    % Mx: double
    %   Output overturning moment

    %% Extract parameters from array

    % coefficients
    QSX1 = P(1);
    QSX2 = P(2);
    QSX3 = P(3);
    
    % input state
    Fy    = X(:,1);
    Fz    = X(:,2);
    gamma = X(:,3);

    %% Function

    Mx = R0.*Fz.*(QSX1.*lambda.VMx + (-QSX2.*gamma + QSX3.*Fy./Fz0).*lambda.Mx);

end

