% **Plotting Options** 
plotCharge = true;    % Set to true if you want to plot charging
plotDischarge = true;  % Set to true if you want to plot discharging

% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 2.5;
jsonstruct.Control.upperCutoffVoltage = 3.5;

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

% **Calculate Capacity for Charging**
if plotCharge
    dt_charge = diff([0; time(charge_idx)]);
    capacity_charge = cumsum(current(charge_idx) .* dt_charge) / 3.6;
    capacity_charge = capacity_charge - min(capacity_charge); % Normalize to start at zero
    capacity_charge = max(capacity_charge) - capacity_charge; % Flip charging curve
end

% **Find and Extract the First Full Discharge Cycle**
if plotDischarge
    discharge_start_idxs = find(diff([0; discharge_idx]) == 1);
    
    if length(discharge_start_idxs) >= 2
        first_discharge_start = discharge_start_idxs(1);
        next_discharge_start = discharge_start_idxs(2);
    else
        first_discharge_start = discharge_start_idxs(1);
        next_discharge_start = length(time);
    end
    
    valid_range = first_discharge_start:next_discharge_start-1;
    time_discharge = time(valid_range) - time(valid_range(1));
    voltage_discharge = voltage(valid_range);
    current_discharge = current(valid_range);

    % Correct capacity calculation
    dt_discharge = diff([0; time_discharge]);
    capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
    capacity_discharge = capacity_discharge - min(capacity_discharge);
end

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
exp_capacity_charge = experimental_data_fullcell.CapacityCby20_charge;
exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
exp_capacity_discharge = experimental_data_fullcell.CapacityCby20_discharge;

% **Plot Full Model Curve vs Experimental Data**
figure;
hold on;

if plotCharge
    plot(capacity_charge, voltage(charge_idx), '-', 'LineWidth', 3, 'Color', [0 0.447 0.741], 'DisplayName', 'Model Charging');
end

if plotDischarge
    plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 3, 'Color', [0.85 0.325 0.098], 'DisplayName', 'Model Discharging');
end

plot(exp_capacity_charge, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental (Charge)');
plot(exp_capacity_discharge, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental (Discharge)');

xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% **Debugging Output**
disp(['Discharge starts at timestep: ', num2str(first_discharge_start)]);
disp(['Voltage range (Discharge): ', num2str(min(voltage_discharge)), ' to ', num2str(max(voltage_discharge)), ' V']);
disp(['Capacity range (Model - Discharge): ', num2str(min(capacity_discharge)), ' to ', num2str(max(capacity_discharge)), ' mAh']);
