% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';
output = runBatteryJson(jsonstruct);
states = output.states;

% Voltage and capacity plot
figure(1); % Create the first figure for the voltage and capacity plot

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% Calculate the capacity from model data
capacity = time .* -1 .* current;

% Plot the model discharge curve
plot((flip(capacity) / (3600 * 1e-3)), voltage, '-', 'LineWidth', 3, 'MarkerSize', 5, 'DisplayName', 'Model');
hold on;

% Extract and plot full cell data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'Full cell');

% Plot half-cell data (optional)
plot_halfcells = false; % Set to true if you want to include half-cell data
if plot_halfcells
    % Load and extract the experimental data for LNMO
    file_path_lnmo = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_LNMO_RCHL374.xlsx';
    experimental_data_lnmo = readtable(file_path_lnmo, 'Sheet', 'Voltage_Capacity');
    exp_voltage_lnmo = experimental_data_lnmo.Voltage;
    exp_capacity_lnmo = experimental_data_lnmo.Capacity;

    % Load and extract the experimental data for XNO
    file_path_xno = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_XNO_RCHX143.xlsx';
    experimental_data_xno = readtable(file_path_xno, 'Sheet', 'Voltage_Capacity');
    exp_voltage_xno = experimental_data_xno.Voltage;
    exp_capacity_xno = experimental_data_xno.Capacity;
    exp_voltage_xno = flip(exp_voltage_xno);
    exp_capacity = flip(exp_capacity_xno);

    % Plot the experimental voltage vs. capacity data for each dataset
    plot(exp_capacity_lnmo, exp_voltage_lnmo, 's-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'LNMO');
    plot(exp_capacity_xno, exp_voltage_xno, '^-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'XNO');
end

% Label the plot
xlabel('Capacity / mA \cdot h');
ylabel('Voltage / V');
legend('Location', 'best');
grid on;
hold off;

% Plot dashboard
figure(2); % Create the second figure for the dashboard
plotDashboard(output.model, states, 'step', length(states), 'theme', 'light', 'size', 'wide');

disp(jsonstruct.Control);