% Load Experimental Full-Cell Data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20_discharge;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20_discharge;
soc_exp = exp_capacity_fullcell ./ max(exp_capacity_fullcell); % Normalize to SOC

% Load Experimental Half-Cell Data
plot_halfcells = true;
if plot_halfcells
    % LNMO Data
    file_path_lnmo = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_LNMO_RCHL374.xlsx';
    experimental_data_lnmo = readtable(file_path_lnmo, 'Sheet', 'Voltage_Capacity');
    exp_voltage_lnmo = experimental_data_lnmo.Voltage_Discharge;
    exp_capacity_lnmo = experimental_data_lnmo.Capacity_Discharge;
    soc_exp_lnmo = exp_capacity_lnmo ./ max(exp_capacity_lnmo);

    % XNO Data
    file_path_xno = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_XNO_RCHX143.xlsx';
    experimental_data_xno = readtable(file_path_xno, 'Sheet', 'Voltage_Capacity');
    exp_voltage_xno = experimental_data_xno.Voltage_Discharge; 
    exp_capacity_xno = experimental_data_xno.Capacity_Discharge; 

    % Sort XNO data and normalize SOC
    [exp_capacity_xno, idx] = sort(exp_capacity_xno, 'descend');
    exp_voltage_xno = exp_voltage_xno(idx);
    soc_exp_xno = flip(exp_capacity_xno ./ max(exp_capacity_xno)); % Flip SOC for XNO
end

% Define Constants
cmax_lnmo = jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.saturationConcentration; 
cmax_xno = jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.saturationConcentration;        
num_points = 100;
soc_common = linspace(0, 1, num_points); % Common SOC grid

% Compute Model OCPs
c_lnmo = soc_common * cmax_lnmo;
c_xno = flip(soc_common) * cmax_xno;
T = 298.15;
ocp_lnmo = computeOCP_LNMO_Morrow(c_lnmo, T, cmax_lnmo);
ocp_xno = computeOCP_XNO_Morrow(c_xno, T, cmax_xno);

% Interpolate for Proper SOC Alignment
ocp_lnmo_interp = interp1(soc_common, ocp_lnmo, soc_common, 'linear', 'extrap');
ocp_xno_interp = interp1(soc_common, ocp_xno, soc_common, 'linear', 'extrap');

% **First Figure: Half-Cell OCPs + Experimental Data**
figure;
plot(soc_common, ocp_lnmo_interp, '-', 'LineWidth', 3, 'DisplayName', 'OCP LNMO');
hold on;
plot(soc_common, ocp_xno_interp, '-', 'LineWidth', 3, 'DisplayName', 'OCP XNO');
if plot_halfcells
    plot(soc_exp_lnmo, exp_voltage_lnmo, 'o', 'MarkerSize', 3, 'DisplayName', 'Experimental LNMO');
    plot(soc_exp_xno, exp_voltage_xno, 'o', 'MarkerSize', 3, 'DisplayName', 'Experimental XNO');
end
xlabel('State of Charge (SOC)', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 18, 'FontWeight', 'bold');
title('OCP of Half-Cells (Model vs Experimental)', 'FontSize', 22, 'FontWeight', 'bold');
grid on;
legend('Location', 'best', 'FontSize', 14);
hold off;

% **Second Figure: Full-Cell OCP Using Reference Script Method**
% Define Full-Cell Calculation Based on LNMO Concentration
c_lnmo_fullcell = linspace(cmax_lnmo, 0, num_points);  % LNMO concentration decreasing
c_xno_fullcell = 0 + (cmax_lnmo - c_lnmo_fullcell);    % XNO determined from LNMO

% Compute OCP Using the Reference Method
ocp_lnmo_fullcell = computeOCP_LNMO_Morrow(c_lnmo_fullcell, T, cmax_lnmo);
ocp_xno_fullcell = computeOCP_XNO_Morrow(c_xno_fullcell, T, cmax_xno);
ocp_cell_fullcell = ocp_lnmo_fullcell - ocp_xno_fullcell;

% Normalize SOC for Full-Cell Calculation
soc_ocp_fullcell = c_lnmo_fullcell ./ cmax_lnmo; 

% Plot Full-Cell OCP
figure;
plot(soc_ocp_fullcell, ocp_cell_fullcell, '-', 'LineWidth', 3, 'DisplayName', 'Model Full Cell');
hold on;
plot(soc_exp, exp_voltage_fullcell, 'o', 'MarkerSize', 3, 'DisplayName', 'Experimental Full Cell');
xlabel('State of Charge (SOC)', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 18, 'FontWeight', 'bold');
title('Full-Cell OCP (Model vs Experimental)', 'FontSize', 22, 'FontWeight', 'bold');
grid on;
legend('Location', 'best', 'FontSize', 14);
hold off;


% Create and export a table with OCP values and their difference
% Flip XNO values for correct alignment with increasing SOC
ocp_xno_flipped = flip(ocp_xno_fullcell); 

% Calculate voltage difference
ocp_diff = ocp_lnmo_fullcell - ocp_xno_flipped;

% Create table
ocp_table = table(soc_ocp_fullcell', ocp_lnmo_fullcell', ocp_xno_flipped', ocp_diff', ...
    'VariableNames', {'SOC', 'Voltage_LNMO', 'Voltage_XNO', 'LNMO_minus_XNO'});

% Save to Excel
writetable(ocp_table, 'OCP_LNMO_XNO_Table.xlsx');