% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.15;
jsonstruct.Control.initialControl = 'charging';

% Run simulation and store results
output = runBatteryJson(jsonstruct);
states = output.states;

% Plot discharge curve (Model vs Experimental)
figure;
hold on;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% Calculate capacity
% capacity = flip(time .* -1 .* current);
capacity = cumsum(time.*current);

% Plot model data
plot((capacity / (3600 * 1e-3)), voltage, '-', 'LineWidth', 3, 'DisplayName', 'Model');

% Load and plot experimental data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'DisplayName', 'Experimental');

% Label plot
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Discharge Curve: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% Save the plot
set(gcf, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]);

% Generate state plots
figure;
sgtitle('State Plots', 'FontSize', 20, 'FontWeight', 'bold');

% Subplot 1: Negative Electrode Concentration
subplot(2, 3, 1);
try
    grid_neg = output.model.NegativeElectrode.Coating.grid;
    concentration_neg = states{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
    plotCellData(grid_neg, concentration_neg, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Negative Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Negative Electrode Concentration.');
end

% Subplot 2: Electrolyte Concentration
subplot(2, 3, 2);
try
    grid_elyte = output.model.Electrolyte.grid;
    concentration_elyte = states{end}.Electrolyte.c ./ 1000;
    plotCellData(grid_elyte, concentration_elyte, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Electrolyte Concentration', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Electrolyte Concentration.');
end

% Subplot 3: Positive Electrode Concentration
subplot(2, 3, 3);
try
    grid_pos = output.model.PositiveElectrode.Coating.grid;
    concentration_pos = states{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
    plotCellData(grid_pos, concentration_pos, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Positive Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Positive Electrode Concentration.');
end

% Subplot 4: Negative Electrode Potential
subplot(2, 3, 4);
try
    potential_neg = states{end}.NegativeElectrode.Coating.phi;
    plotCellData(grid_neg, potential_neg, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Negative Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Negative Electrode Potential.');
end

% Subplot 5: Electrolyte Potential
subplot(2, 3, 5);
try
    potential_elyte = states{end}.Electrolyte.phi;
    plotCellData(grid_elyte, potential_elyte, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Electrolyte Potential', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Electrolyte Potential.');
end

% Subplot 6: Positive Electrode Potential
subplot(2, 3, 6);
try
    potential_pos = states{end}.PositiveElectrode.Coating.phi;
    plotCellData(grid_pos, potential_pos, 'linewidth', 2);
    xlabel('Position / m', 'FontSize', 14, 'FontWeight', 'bold');
    title('Positive Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
catch
    warning('Error plotting Positive Electrode Potential.');
end
