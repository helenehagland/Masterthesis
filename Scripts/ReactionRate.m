% **Plotting Options**
plotCharge = true;    % Set to true if you want to plot charging
plotDischarge = true; % Set to true if you want to plot discharging

% **Load input configuration**
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% **Set control parameters**
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05; % Changeable C-rate
jsonstruct.Control.DRate = 0.05; % Changeable D-rate
jsonstruct.Control.lowerCutoffVoltage = 2.5;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';

% **Define different reaction rate constants (positive electrode only)**
reactionRateFactors = [0.01, 0.1, 1, 10, 100]; % Factor to modify the reaction rate
base_k_pos = jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant;

% **Preallocate storage for results**
capacity_charge_all = cell(length(reactionRateFactors), 1);
voltage_charge_all = cell(length(reactionRateFactors), 1);
capacity_discharge_all = cell(length(reactionRateFactors), 1);
voltage_discharge_all = cell(length(reactionRateFactors), 1);

% **Run simulations for different reaction rate constants**
for i = 1:length(reactionRateFactors)
    k_factor = reactionRateFactors(i);
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = base_k_pos * k_factor;

    % **Run simulation**
    output = runBatteryJson(jsonstruct);
    states = output.states;

    % **Extract model data**
    time = cellfun(@(state) state.time, states);
    voltage = cellfun(@(state) state.Control.E, states);
    current = cellfun(@(state) state.Control.I, states);

    % **Identify charge/discharge cycles**
    charge_idx = current < 0;  
    discharge_idx = current > 0;  

    % **Find cycle start and end indices**
    charge_starts = find(diff([0; charge_idx]) == 1);
    charge_ends = find(diff([charge_idx; 0]) == -1);
    discharge_starts = find(diff([0; discharge_idx]) == 1);
    discharge_ends = find(diff([discharge_idx; 0]) == -1);

    % **Ensure valid cycles exist**
    num_cycles = min([length(charge_starts), length(charge_ends), length(discharge_starts), length(discharge_ends)]);
    if num_cycles == 0
        warning(['No valid cycles detected for k factor = ', num2str(k_factor)]);
        continue;
    end

    % **Extract charge cycle**
    charge_range = charge_starts(1):charge_ends(1);
    time_charge = time(charge_range) - time(charge_range(1));
    voltage_charge = voltage(charge_range);
    current_charge = current(charge_range);
    dt_charge = diff([0; time_charge]);
    capacity_charge = cumsum(abs(current_charge) .* dt_charge) / 3.6;
    capacity_charge = capacity_charge - min(capacity_charge); % Normalize

    capacity_charge_all{i} = capacity_charge;
    voltage_charge_all{i} = voltage_charge;

    % **Extract discharge cycle**
    discharge_range = discharge_starts(1):discharge_ends(1);
    time_discharge = time(discharge_range) - time(discharge_range(1));
    voltage_discharge = voltage(discharge_range);
    current_discharge = current(discharge_range);
    dt_discharge = diff([0; time_discharge]);
    capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
    capacity_discharge = capacity_discharge - min(capacity_discharge); % Normalize

    capacity_discharge_all{i} = capacity_discharge;
    voltage_discharge_all{i} = voltage_discharge;
end

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
exp_capacity_charge = experimental_data_fullcell.CapacityCby20_charge;
exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
exp_capacity_discharge = experimental_data_fullcell.CapacityCby20_discharge;

% **Plot Results**
figure; hold on;
colors = lines(length(reactionRateFactors));

for i = 1:length(reactionRateFactors)
    k_factor = reactionRateFactors(i);
    
    % **Plot charge cycle**
    plot(capacity_charge_all{i}, voltage_charge_all{i}, '-', 'Color', colors(i, :), 'LineWidth', 2, ...
        'DisplayName', ['Charge, k = ', num2str(k_factor), ' * k_{base}']);
    
    % **Plot discharge cycle**
    plot(capacity_discharge_all{i}, voltage_discharge_all{i}, '-', 'Color', colors(i, :), 'LineWidth', 2, ...
        'DisplayName', ['Discharge, k = ', num2str(k_factor), ' * k_{base}']);
end

% **Plot Experimental Data**
plot(exp_capacity_charge, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Exp (Charge)');
plot(exp_capacity_discharge, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Exp (Discharge)');

% **Labels and Legend**
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity for Different Reaction Rate Constants (Positive Electrode)', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;