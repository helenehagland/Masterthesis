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
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.nextControl = 'discharging';

% Create a vector of different diffusion coefficients
k_pos = [1e-12, 2e-12, 5e-12, 1e-11];

% Instantiate empty cell arrays to store outputs and states
output = cell(size(k_pos));
states = cell(size(k_pos));

% Run simulations for each diffusion coefficient
for i = 1:numel(k_pos)
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k_pos(i);
    output{i} = runBatteryJson(jsonstruct);
    states{i} = output{i}.states;
end

% Load Experimental Data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
if plotCharge && plotDischarge
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20_both;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20_both;
    exp_label = 'Experimental (Both)';
elseif plotDischarge && ~plotCharge
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
    exp_label = 'Experimental (Discharge Only)';
elseif plotCharge && ~plotDischarge
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20_charge;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20_charge;
    exp_label = 'Experimental (Charge Only)';
end
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20_both;

% Plot Voltage vs Capacity for Different Diffusion Coefficients
figure;
hold on;
legendEntries = {};

for i = 1:numel(D0)
    time = cellfun(@(state) state.time, states{i});
    voltage = cellfun(@(state) state.('Control').E, states{i});
    current = cellfun(@(state) state.('Control').I, states{i});
    
    charge_idx = (current < 0) & (voltage > jsonstruct.Control.lowerCutoffVoltage);
    discharge_idx = (current > 0) & (voltage < jsonstruct.Control.upperCutoffVoltage);
    
    if plotCharge
        dt_charge = diff([0; time(charge_idx)]);
        capacity_charge = cumsum(current(charge_idx) .* dt_charge) / 3.6;
        capacity_charge = capacity_charge - min(capacity_charge);
        capacity_charge = max(capacity_charge) - capacity_charge;
        plot(capacity_charge, voltage(charge_idx), '-', 'LineWidth', 2);
        legendEntries{end+1} = sprintf('k0 = %.0e (Charge)', k_pos(i));
disp(['k0 = ', num2str(k_pos(i)), ' | Capacity Charge Range: ', num2str(min(capacity_charge)), ' to ', num2str(max(capacity_charge)), ' mAh']);
    end

    if plotDischarge
        discharge_start_idx = find(current > 0, 1, 'first');
        if ~isempty(discharge_start_idx) && any(discharge_idx) && any(current_discharge > 0) && all(voltage_discharge < jsonstruct.Control.upperCutoffVoltage)
            time_discharge = time(discharge_start_idx:end) - time(discharge_start_idx);
            voltage_discharge = voltage(discharge_start_idx:end);
            current_discharge = current(discharge_start_idx:end);
            dt_discharge = diff([0; time_discharge]);
            capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
            capacity_discharge = capacity_discharge - min(capacity_discharge);
            plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 2);
            legendEntries{end+1} = sprintf('k0 = %.0e (Discharge)', k_pos(i));
disp(['k0 = ', num2str(k_pos(i)), ' | Voltage Range (Discharge): ', num2str(min(voltage_discharge)), ' to ', num2str(max(voltage_discharge)), ' V']);
disp(['k0 = ', num2str(k_pos(i)), ' | Current Range (Discharge): ', num2str(min(current_discharge)), ' to ', num2str(max(current_discharge)), ' A']);
disp(['k0 = ', num2str(k_pos(i)), ' | Capacity Discharge Range: ', num2str(min(capacity_discharge)), ' to ', num2str(max(capacity_discharge)), ' mAh']);
        end
    end
end

% Plot Experimental Data
plot(exp_capacity_fullcell, exp_voltage_fullcell, 'k-', 'LineWidth', 2, 'DisplayName', 'Experimental');
legendEntries{end+1} = 'Experimental';

xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Reaction Coefficient vs Experimental', 'FontSize', 16);
legend(legendEntries, 'Location', 'best', 'FontSize', 12);
grid on;
hold off;
