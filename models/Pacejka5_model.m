%%-----------------------------------------------------------------------%%
% filename:         Pacejka5_model.m
% author(s):        Niek van Rossem
% Creation date:    13-09-2024
%%-----------------------------------------------------------------------%%

function out = Pacejka5_model(P, X)
    %% Documentation
    % This function calculates the Fx, Fy, Mx, or Mz based on the PACE5
    % model as developed by Bill Cobb. This model works for all
    % combinations of units, as long as you keep it consistent.
    %
    % INPUTS
    % ======
    % P: 5x1 matrix
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
    %       X(:,1) = S  -> slip ratio or slip angle
    %       X(:,2) = Fz -> Vertical load
    % OUTPUTS
    % =======
    % out: double
    %   Output force or moment.
    
    %% Function

    % check if sixth parameter is included
    if isequal(length(P), 6)
        SV = P(6);
    else
        SV = 0;
    end

    % calculate peak factor
    D = (P(1) + P(2)./1000.*X(:,2)).*X(:,2);

    % calculate output
    out = D.*sin((P(4) + (P(5)./1000.*X(:,2))).*atan(P(3).*(X(:,1)))) + SV;

end
