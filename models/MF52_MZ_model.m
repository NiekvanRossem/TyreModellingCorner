%%-----------------------------------------------------------------------%%
% filename:         MF52_MZ_model.m
% author(s):        Niek van Rossem
% Creation date:    02-11-2024
%%-----------------------------------------------------------------------%%

function Mz = MF52_MZ_model(P, X, Tyre, Fz0, R0, lambda)
    %% Documentation
    % This function calculates the Mz based on the Magic Formula 5.2 model. 
    % This model works for all combinations of units, as long as you keep 
    % it consistent.
    %
    % INPUTS
    % ======
    % P: 25x1 matrix
    %   Set of model parameters:
    %
    % X: Nx3 matrix
    %   Set of input states (N is the size of the input array you would
    %   like to have evaluated)
    %
    % Fz0: double
    %   Nominal vertical load.
    %
    % lambda: structure
    %   Structure containing all the scaling factors
    %
    % OUTPUTS
    % =======
    % Mz: double
    %   Output self-aligning moment

    %% Extract parameters from array

    % coefficients
    QBZ1 = P(1);
    QBZ2 = P(2);
    QBZ3 = P(3);
    QBZ4 = P(4);
    QBZ5 = P(5);
    QBZ9 = P(6);
    QBZ10 = P(7);
    QCZ1 = P(8);
    QDZ1 = P(9);
    QDZ2 = P(10);
    QDZ3 = P(11);
    QDZ4 = P(12);
    QDZ6 = P(13);
    QDZ7 = P(14);
    QDZ8 = P(15);
    QDZ9 = P(16);
    QEZ1 = P(17);
    QEZ2 = P(18);
    QEZ3 = P(19);
    QEZ4 = P(20);
    QEZ5 = P(21);
    QHZ1 = P(22);
    QHZ2 = P(23);
    QHZ3 = P(24);
    QHZ4 = P(25);
    
    % input state
    Fy    = X(:,1);
    Fz    = X(:,2);
    gamma = X(:,3);

    % normalised load
    dFz = (Fz - Fz0)./Fz0;

    %% Reload Fy fit parameters

    % effective camber angle
    gamma_y = gamma.*lambda.mu_y;

    % horizontal offset
    S_Hy = (Tyre.PHY1 + Tyre.PHY2.*dFz) + lambda.Hy + Tyre.PHY3.*gamma_y;

    % vertical offset
    S_Vy = Fz.*((Tyre.PVY1 + Tyre.PVY2.*dFz).*lambda.Vy + (Tyre.PVY3 + Tyre.PVY4.*dFz).*gamma_y).*lambda.mu_y;

    % peak factor
    Dy = (Tyre.PDY1 + Tyre.PDY2.*dFz).*(1 - Tyre.PDY3.*gamma_y.^2).*lambda.mu_y.*Fz;
    
    % shape factor
    Cy = Tyre.PCY1.*lambda.Cy;

    % cornering stiffness
    Ky = Tyre.PKY1.*Fz0.*sind(2*atan(Fz./(Tyre.PKY2.*Fz0))).*(1 - Tyre.PKY3.*abs(gamma_y));

    % stiffness factor
    By = Ky./(Cy.*Dy);

    %% Function

    % scaled camber angle
    gamma_z = gamma.*lambda.gamma_z;

    % horizontal shifts
    S_Ht = QHZ1 + QHZ2.*dFz + (QHZ3 + QHZ4.*dFz).*gamma_z;
    S_Hr = S_Hy + S_Vy./Ky;

    % effective slip angles
    alpha_t = alpha + S_Ht;
    alpha_r = alpha + S_Hr;

    % stiffness factors
    BT = (QBZ1 + QBZ2.*dFz + QBZ3.*dFz.^2).*(1 + QBZ4.*gamma_z + QBZ5.*abs(gamma_z)).*lambda.Ky./lambda.mu_y;
    BR = QBZ9.*lambda.Ky./lambda.mu_y + QBZ10.*By.*Cy;

    % shape factor
    CT = QCZ1;

    % peak factors
    DT = Fz.*(QDZ1 + QDZ2.*dFz).*(1 + QDZ3.*gamma_z + QDZ4.*gamma_z.^2).*(R0./Fz0).*lambda.t;
    DR = Fz.*((QDZ6 + QDZ7.*dFz).*lambda.r + (QDZ8 + QDZ9.*dFz).*gamma_z).*R0.*lambda.mu_y;

    % curvature factor
    ET = max((QEZ1 + QEZ2.*dFz + QEZ3.*dFz.^2).*(1 + (QEZ4 + QEZ5.*gamma_z).*(2./pi).*atand(BT.*CT.*alpha_t)), 1);

    % Pneumatic trail
    t = DT.*cosd(CT.*atand(BT.*alpha_t - ET.*(BT.*alpha_t - atand(BT.*alpha_t)))).*cosd(alpha);

    % Residual torque
    Mzr = DR.*cosd(atand(BR.*alpha_r)).*cosd(alpha);

    % full self-aligning moment
    Mz  = -t.*Fy + Mzr;

end

