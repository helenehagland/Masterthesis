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
jsonstruct.Control.upperCutoffVoltage = 3.47;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-11;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 9e-13;

% jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 2e-15;
% jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 8e-16;
% 
% jsonstruct.NegativeElectrode.Coating.ActiveMaterial.electronicConductivity = 100;
% jsonstruct.PositiveElectrode.Coating.ActiveMaterial.electronicConductivity = 100;
% 
% jsonstruct.NegativeElectrode.Coating.bruggemanCoefficient = 1;
% jsonstruct.PositiveElectrode.Coating.bruggemanCoefficient = 1;


% Start with charging and simulate the full curve
jsonstruct.Control.initialControl = 'charging';

% Run simulation and store results
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% Split into Charging and Discharging Phases
charge_idx = current < 0;  % Negative current = charging
discharge_idx = current > 0;  % Positive current = discharging

% Prepare for plotting
charge_end_idxs = find(diff([charge_idx; 0]) == -1); 
num_cycles = min(jsonstruct.Control.numberOfCycles, 5);

%% ===== FIGURE 1: Voltage vs. Capacity =====
figure;
hold on;

for cycle = 1:num_cycles
    % Charging
    if length(find(diff([0; charge_idx]) == 1)) >= cycle && length(charge_end_idxs) >= cycle
        charge_start = find(diff([0; charge_idx]) == 1, cycle, 'first');
        charge_end = charge_end_idxs(cycle);
        valid_charge_range = charge_start:charge_end;
        time_charge = time(valid_charge_range) - time(valid_charge_range(1));
        voltage_charge = voltage(valid_charge_range);
        current_charge = current(valid_charge_range);
        dt_charge = diff([0; time_charge]);
        capacity_charge = cumsum(abs(current_charge) .* dt_charge) / 3.6;
        capacity_charge = capacity_charge - min(capacity_charge); 
        plot(capacity_charge, voltage_charge, '-', 'LineWidth', 2, 'DisplayName', ['Model Charging Cycle ' num2str(cycle)]);
    end

    % Discharging
    discharge_starts = find(diff([0; discharge_idx]) == 1);
    discharge_ends = find(diff([discharge_idx; 0]) == -1);
    if length(discharge_starts) >= cycle && length(discharge_ends) >= cycle
        discharge_start = discharge_starts(cycle);
        discharge_end = discharge_ends(cycle);
        if cycle <= length(charge_end_idxs)
            charge_end_voltage = voltage(charge_end_idxs(cycle));
            voltage(discharge_start) = charge_end_voltage;
        end
        valid_discharge_range = discharge_start:discharge_end;
        time_discharge = time(valid_discharge_range) - time(valid_discharge_range(1));
        voltage_discharge = voltage(valid_discharge_range);
        current_discharge = current(valid_discharge_range);
        dt_discharge = diff([0; time_discharge]);
        capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
        capacity_discharge = capacity_discharge - min(capacity_discharge);
        plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 2, 'DisplayName', ['Model Discharging Cycle ' num2str(cycle)]);
    end
end

% Load experimental data
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

%% ===== FIGURE 2: Voltage vs. Time =====
figure;
hold on;

% Extract time series for model charge
time_charge_model = time(charge_idx);
voltage_charge_model = voltage(charge_idx);

% Normalize model charge time to start from zero
time_charge_model = time_charge_model - time_charge_model(1);

% === Trim the CV phase for the plot (optional) ===
cv_cutoff_index = find(voltage_charge_model >= 3.47, 1, 'first');
if ~isempty(cv_cutoff_index)
    time_charge_model = time_charge_model(1:cv_cutoff_index);
    voltage_charge_model = voltage_charge_model(1:cv_cutoff_index);
end
% ================================================

% Plot model charge
plot(time_charge_model / 3600, voltage_charge_model, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');

% Extract time series for model discharge
time_discharge_model = time(discharge_idx);
voltage_discharge_model = voltage(discharge_idx);

% Normalize model discharge time to start from zero
time_discharge_model = time_discharge_model - time_discharge_model(1);

% Plot model discharge
plot(time_discharge_model / 3600, voltage_discharge_model, '-', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Model Discharge');

% Load experimental data (already loaded earlier)
exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
exp_time_charge = experimental_data_fullcell.TimeCby20_charge;
exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
exp_time_discharge = experimental_data_fullcell.TimeCby20_discharge;

% Convert experimental time (duration strings) to seconds
exp_time_charge_sec = seconds(duration(exp_time_charge));
exp_time_discharge_sec = seconds(duration(exp_time_discharge));

% Plot experimental charge
plot(exp_time_charge_sec / 3600, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental Charge');

% Plot experimental discharge
plot(exp_time_discharge_sec / 3600, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental Discharge');
xlabel('Time / h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Time: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;