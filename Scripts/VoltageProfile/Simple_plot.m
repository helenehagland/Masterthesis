%jsonstruct = parseBattmoJson('ProjectThesis/Parameter_Files/SampleInput_LNMO.json');
jsonstruct = parseBattmoJson('Documents/MATLAB/Software/BattMo/Examples/JsonDataFiles/sample_input.json');


figure()

% Set control parameters
%jsonstruct.Control.DRate = 0.05;
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


plot_experimental = false;
if plot_experimental
    % Load the experimental data from the Excel file
    file_path = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
    experimental_data = readtable(file_path);

    % Extract experimental voltage and capacity data
    exp_voltage = experimental_data.VoltageCby20;
    exp_capacity = experimental_data.CapacityCby20;

    % Plot the experimental voltage vs. capacity data
    plot(exp_capacity, exp_voltage, '-', 'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', 'Experimental Data')
end

% Label the plot
xlabel('Capacity / mA \cdot h')
ylabel('Voltage / V')
legend('Location', 'best')
grid on
hold off
