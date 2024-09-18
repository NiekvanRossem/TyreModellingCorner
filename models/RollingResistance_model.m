%%-----------------------------------------------------------------------%%
% filename:         RollingResistance_model.m
% author(s):        Niek van Rossem
% Creation date:    18-09-2024
%%-----------------------------------------------------------------------%%

function MY = RollingResistance_model(P, X, RO, FZ0, V0, P0, LMY)
    %% Documentation
    % This function calculates the rolling resistance moment MY based on
    % the vertical load, pressure, and velocity. The model itself is based
    % on Pacejka's implementation in MF 6.1.2 (for more information see 
    % Tire and Vehicle Dynamics by Pacejka & Besselink, equation 4.E70).
    %
    % INPUTS
    % ======
    % P: 8x1 matrix
    %   Set of model parameters:
    %       P(1)  = QSY1 -> 
    %       P(2)  = QSY2 -> 
    %       P(3)  = QSY3 -> 
    %       P(4)  = QSY4 -> 
    %       P(5)  = QSY5 -> 
    %       P(6)  = QSY6 -> 
    %       P(7)  = QSY7 -> 
    %       P(8)  = QSY8 ->
    % X: Nx5 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %       X(:,1) = FX -> slip ratio or slip angle
    %       X(:,2) = FZ -> Vertical load
    %       X(:,3) = VX -> Velocity
    %       X(:,4) = IA -> Inclination angle
    %       X(:,5) = P  -> Pressure
    % OUTPUTS
    % =======
    % MY: double
    %   Rolling resistance moment
    
    %% Function

    % calculate rolling resistance moment
    MY = X(:,2).*RO.*...
    (P(1) + ...
     P(2).*X(:,1)./FZ0 + ...
     P(3).*abs(X(:,3)./V0) + ...
     P(4).*abs(X(:,3)./V0).^4 + ...
     (P(5) + P(6).*X(:,2)./FZ0).*X(:,4).^2).*...
     ((X(:,2)./FZ0).^P(7).*(X(:,5)./P0).^P(8)).*LMY;

end