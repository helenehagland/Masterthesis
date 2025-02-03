% Experimental Full-Cell Data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;

% Normalize Full-Cell Experimental Capacity to SOC
max_capacity_exp = max(exp_capacity_fullcell); % Maximum experimental capacity
soc_exp = exp_capacity_fullcell ./ max_capacity_exp; % Normalize to SOC

% Experimental Half-Cell Data
plot_halfcells = true; % Set to true to include half-cell data
if plot_halfcells
    % LNMO Experimental Data
    file_path_lnmo = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_LNMO_RCHL374.xlsx';
    experimental_data_lnmo = readtable(file_path_lnmo, 'Sheet', 'Voltage_Capacity');
    exp_voltage_lnmo = experimental_data_lnmo.Voltage;
    exp_capacity_lnmo = experimental_data_lnmo.Capacity;
    soc_exp_lnmo = exp_capacity_lnmo ./ max(exp_capacity_lnmo); % Normalize to SOC

    % XNO Experimental Data
    file_path_xno = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_XNO_RCHX143.xlsx';
    experimental_data_xno = readtable(file_path_xno, 'Sheet', 'Voltage_Capacity');
    exp_voltage_xno = experimental_data_xno.Voltage; 
    exp_capacity_xno = experimental_data_xno.Capacity; 
    soc_exp_xno = flip(exp_capacity_xno ./ max(exp_capacity_xno)); % Normalize and flip SOC for XNO
end

% OCP Data
cmax_lnmo = 23286.29529; % Max lithium concentration for LNMO
cmax_xno = 35259;        % Max lithium concentration for XNO

% Generate Concentration Data
c_lnmo = linspace(cmax_lnmo, 0, 100);
c_xno = 0 + (cmax_lnmo - c_lnmo);

% Compute OCP for Each Component
T = 298.15; % Example temperature; ensure T is defined
ocp_lnmo = computeOCP_LNMO_Morrow(c_lnmo, T, cmax_lnmo);
ocp_xno = computeOCP_XNO_Morrow(c_xno, T, cmax_xno);

% Compute Full-Cell OCP
ocp_cell = ocp_lnmo - ocp_xno;

% Normalize OCP Data to SOC
soc_ocp = c_lnmo ./ cmax_lnmo; % SOC for OCP data

% Plot the Data
figure;
% Plot OCP Data
plot(soc_ocp, ocp_lnmo, '-', 'LineWidth', 3, 'DisplayName', 'OCP LNMO');
hold on;
plot(soc_ocp, ocp_xno, '-', 'LineWidth', 3, 'DisplayName', 'OCP XNO');
plot(soc_ocp, ocp_cell, '-', 'LineWidth', 3, 'DisplayName', 'Model');

% Plot Full-Cell Experimental Data
plot(soc_exp, exp_voltage_fullcell, '-', 'LineWidth', 3, 'DisplayName', 'Full cell (Normalized)');

% Plot Half-Cell Experimental Data (if enabled)
if plot_halfcells
    plot(soc_exp_lnmo, exp_voltage_lnmo, '-', 'LineWidth', 3, 'MarkerSize', 3, 'DisplayName', 'Experimental LNMO');
    plot(soc_exp_xno, exp_voltage_xno, '-', 'LineWidth', 3, 'MarkerSize', 3, 'DisplayName', 'Experimental XNO');
end
% Customize the Plot
xlabel('State of Charge (SOC)', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 18, 'FontWeight', 'bold');
title('OCP of Model and Experimental Data', 'FontSize', 22, 'FontWeight', 'bold');
grid on;

% Set x-axis ticks and labels to reverse from 1 to 0
ax = gca; % Get current axis
ax.XTick = linspace(0, 1, 11); % Define ticks at uniform intervals (0, 0.1, ..., 1.0)
ax.XTickLabel = num2str(flip(ax.XTick(:))); % Reverse and set tick labels
ax.FontSize = 14;
ax.FontWeight = 'bold';

legend('Location', 'best', 'FontSize', 14);
hold off;

% Set figure size for the output
figureHandle = gcf; % Get current figure handle
set(figureHandle, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen
set(figureHandle, 'PaperUnits', 'inches');
set(figureHandle, 'PaperSize', [16, 12]); % Set size to 16x12 inches
set(figureHandle, 'PaperPosition', [0, 0, 16, 12]); % Fill the page

% Save the plot as a PDF
exportgraphics(figureHandle, '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/OCP.pdf', ...
    'ContentType', 'vector', 'Resolution', 300);
