% **Plotting Options** 
plotCharge = false;    % Set to true if you want to plot charging
plotDischarge = true;  % Set to true if you want to plot discharging

% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.15;

% Start with charging and simulate the full curve
jsonstruct.Control.initialControl = 'charging';

% Run simulation and store results
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% **Split into Charging and Discharging Phases**
charge_idx = current < 0;  % Negative current = charging
discharge_idx = current > 0;  % Positive current = discharging

% **Calculate Capacity for Charging and Discharging Separately**
% Charging Capacity
if plotCharge
    dt_charge = diff([0; time(charge_idx)]);
    capacity_charge = cumsum(current(charge_idx) .* dt_charge) / 3.6;
    capacity_charge = capacity_charge - min(capacity_charge); % Normalize to start at zero
    capacity_charge = max(capacity_charge) - capacity_charge; % Flip charging curve
end

% **Discharging Capacity - Using Correct Logic from Working Version**
if plotDischarge
    % Find the first discharge index
    discharge_start_idx = find(current > 0, 1, 'first'); % First index where current is positive (discharging)

    % Ensure we only plot discharge
    if ~isempty(discharge_start_idx)
        time_discharge = time(discharge_start_idx:end) - time(discharge_start_idx); % Normalize time to start at zero
        voltage_discharge = voltage(discharge_start_idx:end);
        current_discharge = current(discharge_start_idx:end);

        % Correct capacity calculation
        dt_discharge = diff([0; time_discharge]); % Time step differences
        capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6; % Convert to mAh
        capacity_discharge = capacity_discharge - min(capacity_discharge); % Ensure it starts at zero
    end
end

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';

% Determine which experimental data to load
if plotCharge && plotDischarge
    % Load both charging and discharging data
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20_both;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20_both;
    exp_label = 'Experimental (Both)';
elseif plotDischarge && ~plotCharge
    % Load only discharging data
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
    exp_label = 'Experimental (Discharge Only)';
end

% **Plot Full Model Curve vs Experimental Data**
figure;
hold on;

% **Plot Model Data**
if plotCharge
    plot(capacity_charge, voltage(charge_idx), '-', 'LineWidth', 3, 'Color', [0 0.447 0.741], 'DisplayName', 'Model Charging');
end

if plotDischarge
    plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 3, 'Color', [0.85 0.325 0.098], 'DisplayName', 'Model Discharging');
end

% **Plot Experimental Data**
plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', exp_label);

% **Label Plot**
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% **Debugging Output**
if plotDischarge
    disp(['Discharge starts at timestep: ', num2str(discharge_start_idx)]);
    disp(['Voltage range (Discharge): ', num2str(min(voltage_discharge)), ' to ', num2str(max(voltage_discharge)), ' V']);
    disp(['Capacity range (Model - Discharge): ', num2str(min(capacity_discharge)), ' to ', num2str(max(capacity_discharge)), ' mAh']);
end
if plotCharge
    disp(['Charging Capacity range (Model): ', num2str(min(capacity_charge)), ' to ', num2str(max(capacity_charge)), ' mAh']);
end