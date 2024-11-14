jsonstruct = parseBattmoJson('Matlab/Parameter_Files/SampleInput_LNMO.json');
%jsonstruct = parseBattmoJson('Documents/MATLAB/Software/BattMo/Examples/JsonDataFiles/sample_input.json');


figure()

% Set control parameters
jsonstruct.Control.DRate = 0.05;
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.('Control').E, states);
current = cellfun(@(state) state.('Control').I, states);

% Calculate the capacity from model data
capacity = time .* current;

% Plot the model discharge curve
plot((capacity / (3600 * 1e-3)), voltage, '-', 'LineWidth', 3, 'MarkerSize', 5,'DisplayName', 'Model') % Convert to mA·h
hold on


plot_experimental = true;
if plot_experimental
    % Load and extract the experimental data for full cell
    file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
    
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
    
    % Plot the experimental voltage vs. capacity data for each dataset
    plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', 'Full cell')
    hold on
    plot(exp_capacity_lnmo, exp_voltage_lnmo, 's-', 'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', 'LNMO')
    plot(exp_capacity_xno, exp_voltage_xno, '^-', 'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', 'XNO')
end

% Label the plot
xlabel('Capacity / mA \cdot h')
ylabel('Voltage / V')
legend('Location', 'best')
grid on
hold off
