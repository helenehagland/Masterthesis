% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.15;

% Start with charging but only plot discharge
jsonstruct.Control.initialControl = 'charging';

% Run simulation and store results
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% **Find the first discharge index**
discharge_start_idx = find(current > 0, 1, 'first'); % First index where current is positive (discharging)

% **Ensure we only plot discharge**
if ~isempty(discharge_start_idx)
    time = time(discharge_start_idx:end) - time(discharge_start_idx); % Normalize time to start at zero
    voltage = voltage(discharge_start_idx:end);
    current = current(discharge_start_idx:end);
end

% **Correct capacity calculation**
dt = diff([0; time]); % Time step differences
capacity = cumsum(current .* dt) / 3.6; % Convert to mAh
capacity = capacity - min(capacity); % Ensure it starts at zero

% **Plot discharge curve (Model vs Experimental)**
figure;
hold on;

% **Plot model data**
plot(capacity, voltage, '-', 'LineWidth', 3, 'DisplayName', 'Model');

% **Load and plot experimental data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'DisplayName', 'Experimental');

% **Label plot**
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Discharge Curve: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% **Debugging Output**
disp(['Discharge starts at timestep: ', num2str(discharge_start_idx)]);
disp(['Voltage range: ', num2str(min(voltage)), ' to ', num2str(max(voltage)), ' V']);
disp(['Capacity range (Model): ', num2str(min(capacity)), ' to ', num2str(max(capacity)), ' mAh']);