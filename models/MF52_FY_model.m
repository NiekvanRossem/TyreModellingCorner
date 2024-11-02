%%-----------------------------------------------------------------------%%
% filename:         MF52_FY_model.m
% author(s):        Niek van Rossem
% Creation date:    08-10-2024
%%-----------------------------------------------------------------------%%

function Fy = MF52_FY_model(P, X, Fz0, lambda, Settings)
    %% Documentation
    % This function calculates the Fy based on the Magic Formula 5.2 model. 
    % This model works for all combinations of units, as long as you keep 
    % it consistent.
    %
    % INPUTS
    % ======
    % P: 18x1 matrix
    %   Set of model parameters:
    %       P(1)  = PCY1
    %       P(2)  = PDY1
    %       P(3)  = PDY2
    %       P(4)  = PDY3
    %       P(5)  = PEY1
    %       P(6)  = PEY2
    %       P(7)  = PEY3
    %       P(8)  = PEY4
    %       P(9)  = PKY1
    %       P(10) = PKY2
    %       P(11) = PKY3
    %       P(12) = PHY1
    %       P(13) = PHY2
    %       P(14) = PHY3
    %       P(15) = PVY1
    %       P(16) = PVY2
    %       P(17) = PVY3
    %       P(18) = PVY4
    % X: Nx3 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %       X(:,1) = S  -> slip ratio or slip angle
    %       X(:,2) = Fz -> vertical load
    %       X(:,3) = IA -> inclination angle
    % Fz0: double
    %   Nominal vertical load.
    % lambda: structure
    %   Structure containing all the scaling factors
    %       mu_y -> friction scaling
    %       Cy   -> shape scaling
    %       Hy   -> horizontal shift scaling
    %       Vy   -> vertical shift scaling
    % Settings: Structure
    %   Structure containing the settings for the fitting / evaluation
    %   process. For this function the only relevant setting is the 
    %   AngleUnit.
    %
    % OUTPUTS
    % =======
    % Fy: double
    %   Output side force.

    %% Extract parameters from array

    % coefficients
    PCY1 = P(1);
    PDY1 = P(2);
    PDY2 = P(3);
    PDY3 = P(4);
    PEY1 = P(5);
    PEY2 = P(6);
    PEY3 = P(7);
    PEY4 = P(8);
    PKY1 = P(9);
    PKY2 = P(10);
    PKY3 = P(11);
    PHY1 = P(12);
    PHY2 = P(13);
    PHY3 = P(14);
    PVY1 = P(15);
    PVY2 = P(16);
    PVY3 = P(17);
    PVY4 = P(18);
    
    % input state
    alpha = X(:,1);
    Fz    = X(:,2);
    gamma = X(:,3);

    %% Function

    % if Settings.AngleUnit == "deg"
    %     alpha = deg2rad(alpha);
    % end

    % normalised load
    dFz = (Fz - Fz0)./Fz0;

    % effective inclination angle
    gamma_y = gamma.*lambda.mu_y;

    % horizontal offset
    S_Hy = (PHY1 + PHY2.*dFz) + lambda.Hy + PHY3.*gamma_y;

    % vertical offset
    S_Vy = Fz.*((PVY1 + PVY2.*dFz).*lambda.Vy + (PVY3 + PVY4.*dFz).*gamma_y).*lambda.mu_y;

    % effective slip angle
    alpha_y = alpha + S_Hy;

    % friction coefficient
    mu = (PDY1 + PDY2.*dFz).*(1 - PDY3.*gamma_y.^2).*lambda.mu_y;

    % shape factor
    Cy = PCY1.*lambda.Cy;

    % peak factor
    Dy = mu.*Fz;

    % curvature factor
    Ey = (PEY1 + PEY2.*dFz).*(1 - (PEY3 + PEY4.*gamma_y).*sign(alpha_y));
    
    % cornering stiffness
    Ky = PKY1.*Fz0.*sind(2*atan(Fz./(PKY2.*Fz0))).*(1 - PKY3.*abs(gamma_y));

    % stiffness factor
    By = Ky./(Cy.*Dy);

    % output
    Fy = Dy.*sind(Cy.*atand(By.*alpha_y - Ey.*(By.*alpha_y - atand(By.*alpha_y)))) + S_Vy;

end

