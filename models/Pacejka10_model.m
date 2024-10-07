%%-----------------------------------------------------------------------%%
% filename:         Pacejka10_model.m
% author(s):        Niek van Rossem
% Creation date:    30-09-2024
%%-----------------------------------------------------------------------%%

function out = Pacejka10_model(Par, X, Fz0, lambda, Settings)
    %% Documentation
    % This function calculates the Fx, Fy, Mx, or Mz based on the Pacejka10
    % model. This model works for all
    % combinations of units, as long as you keep it consistent.
    %
    % INPUTS
    % ======
    % P: 10x1 matrix
    %   Set of model parameters:
    %       P(1) = C
    %       P(2) = D1   -> Peak factor
    %       P(3) = D2   -> Peak factor load sensitivity
    %       P(4) = E    -> 
    %       P(5) = P    -> 
    %       P(6) = S_H1 -> Horizontal offset
    %       P(7) = S_H2 -> Horizontal offset load sensitivity
    %       P(8) = S_V  -> Vertical offset
    % X: Nx2 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %       X(:,1) = S  -> slip ratio or slip angle
    %       X(:,2) = Fz -> Vertical load
    % Fz0: double
    %   Nominal vertical load.
    % lambda: double
    %   Scaling factor for the friction coefficient.
    % Settings: Structure
    %   Structure containing the settings for the fitting / evaluation
    %   process. For this function the only relevant setting is the 
    %   AngleUnit.
    %
    % OUTPUTS
    % =======
    % out: double
    %   Output force or moment.

    %% Extract parameters from array

    % coefficients
    C       = Par(1);
    D1      = Par(2);
    D2      = Par(3);
    E       = Par(4);
    P       = Par(5);
    S_H1    = Par(6);
    S_H2    = Par(7);
    S_V     = Par(8);

    % input state
    S   = X(:,1);
    Fz  = X(:,2);

    %% Function

    % calculate normalised load
    dFz = (Fz - Fz0)./Fz0;

    % calculate effective slip angle
    S_eff = S + S_H1 + S_H2.*dFz;

    % calculate peak factor
    D = Fz.*(D1 + D2.*dFz).*lambda;

    % output
    if Settings.AngleUnit == "deg"
        out = S_V + D.*sind(C.*atand(P.*S_eff - E.*(P.*S_eff - atand(P.*S_eff))));
    elseif Settings.AngleUnit == "rad"
        out = S_V + D.*sin(C.*atan(P.*S_eff - E.*(P.*S_eff - atan(P.*S_eff))));
    end
end

