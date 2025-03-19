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
jsonstruct.Control.numberOfCycles = 1; % Run one full cycles

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

% **Extract All Charge and Discharge Cycles and Normalize to Capacity = 0**
figure;
hold on;

for cycle = 1:5
    % Find charge cycle start and end
    if length(find(diff([0; charge_idx]) == 1)) >= cycle && length(find(diff([charge_idx; 0]) == -1)) >= cycle
        charge_start = find(diff([0; charge_idx]) == 1, cycle, 'first');
        charge_end = find(diff([charge_idx; 0]) == -1, cycle, 'first');
        valid_charge_range = charge_start(end):charge_end(end);
        time_charge = time(valid_charge_range) - time(valid_charge_range(1));
        voltage_charge = voltage(valid_charge_range);
        current_charge = current(valid_charge_range);
        dt_charge = diff([0; time_charge]);
        capacity_charge = cumsum(abs(current_charge) .* dt_charge) / 3.6;
        capacity_charge = capacity_charge - min(capacity_charge); % Normalize to start at 0
        plot(capacity_charge, voltage_charge, '-', 'LineWidth', 2, 'DisplayName', ['Model Charging Cycle ', num2str(cycle)]);
    end
    
    % Find discharge cycle start and end
    if length(find(diff([0; discharge_idx]) == 1)) >= cycle && length(find(diff([discharge_idx; 0]) == -1)) >= cycle
        discharge_start = find(diff([0; discharge_idx]) == 1, cycle, 'first');
        discharge_end = find(diff([discharge_idx; 0]) == -1, cycle, 'first');
        valid_discharge_range = discharge_start(end):discharge_end(end);
        time_discharge = time(valid_discharge_range) - time(valid_discharge_range(1));
        voltage_discharge = voltage(valid_discharge_range);
        current_discharge = current(valid_discharge_range);
        dt_discharge = diff([0; time_discharge]);
        capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
        capacity_discharge = capacity_discharge - min(capacity_discharge); % Normalize to start at 0
        plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 2, 'DisplayName', ['Model Discharging Cycle ', num2str(cycle)]);
    end
end

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
exp_capacity_charge = experimental_data_fullcell.CapacityCby20_charge;
exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
exp_capacity_discharge = experimental_data_fullcell.CapacityCby20_discharge;

plot(exp_capacity_charge, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental (Charge)');
plot(exp_capacity_discharge, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental (Discharge)');

xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;
