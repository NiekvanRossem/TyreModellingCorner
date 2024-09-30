%%-----------------------------------------------------------------------%%
% filename:         Pacejka5_model.m
% author(s):        Niek van Rossem
% Creation date:    13-09-2024
%%-----------------------------------------------------------------------%%

function out = Pacejka5_model(P, X, Settings)
    %% Documentation
    % This function calculates the Fx, Fy, Mx, or Mz based on the PACE5
    % model as developed by Bill Cobb. This model works for all
    % combinations of units, as long as you keep it consistent.
    %
    % INPUTS
    % ======
    % P: 5x1 matrix or 6x1 matrix
    %   Set of model parameters:
    %       P(1) = D1 -> Peak factor
    %       P(2) = D2 -> Peak factor load sensitivity
    %       P(3) = B  -> Stiffness factor
    %       P(4) = C  -> Curvature factor
    %       P(5) = Bp -> Curvature factor load sensitivity
    %       P(6) = Sv -> OPTIONAL, this is the vertical offset
    % X: Nx2 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %       X(:,1) = S  -> Slip ratio or slip angle
    %       X(:,2) = Fz -> Vertical load
    % Settings: Structure
    %   Structure containing the settings for the fitting / evaluation
    %   process. For this function the only relevant setting is the
    %   AngleUnit, which is used to denote the unit used for the angle
    %   (either deg or rad).
    %
    % OUTPUTS
    % =======
    % out: double
    %   Output force or moment.
    
    %% Extract parameters from array

    % coefficients
    D1  = P(1);
    D2  = P(2);
    B   = P(3);
    C   = P(4);
    Bp  = P(5);

    % input state
    S   = X(:,1);
    Fz  = X(:,2);

    %% Function

    % check if sixth parameter is included
    if isequal(length(P), 6)
        SV = P(6);
    else
        SV = 0;
    end

    % calculate peak factor
    D = (D1 + D2/1000.*Fz).*Fz;

    % calculate output
    if Settings.AngleUnit == "deg"
        out = D.*sind((C + Bp/1000.*Fz).*atand(B.*S)) + SV;
    elseif Settings.AngleUnit == "rad"
        out = D.*sin((C + Bp/1000.*Fz).*atan(B.*S)) + SV;
    else
        disp("Invalid angle unit.");
    end

end

