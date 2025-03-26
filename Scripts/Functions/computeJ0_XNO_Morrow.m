function j0 = computeJ0_XNO_Morrow(cElectrodeSurface)
    cmax = 35259;  % XNO saturation concentration
    cmin = 0.2 * cmax;
    c100 = 0.85 * cmax;

    SOC = (cElectrodeSurface - cmin) / (c100 - cmin);
    SOC = max(min(SOC, 1), 0);  % Clip SOC to [0, 1]

    j0 = (1 - (2*SOC - 1).^2);
    j0 = 2e-5 * j0;  % Slightly different scaling if needed
end