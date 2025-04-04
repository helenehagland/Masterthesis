% === Load Input Configuration ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 2.5;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.dIdtLimit = 5e-7;
jsonstruct.Control.dEdtLimit = 1e-5;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.SOC = 0.01;

% jsonstruct.TimeStepping.totalTime = 750000;
jsonstruct.TimeStepping.numberOfTimeSteps = 400;


% Overwrite parameter values
jsonstruct.NegativeElectrode.Coating.thickness = jsonstruct.NegativeElectrode.Coating.thickness .* 0.94;
jsonstruct.PositiveElectrode.Coating.thickness = jsonstruct.PositiveElectrode.Coating.thickness .* 0.94;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.01;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-12;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-13;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;

% === Run Simulation ===
output = runBatteryJson(jsonstruct);
states = output.states;

% === Extract Model Data ===
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

charge_idx = current < 0;
discharge_idx = current > 0;

charge_end_idxs = find(diff([charge_idx; 0]) == -1);
discharge_starts = find(diff([0; discharge_idx]) == 1);
discharge_ends = find(diff([discharge_idx; 0]) == -1);
num_cycles = min(jsonstruct.Control.numberOfCycles, 5);

%% === FIGURE 1: Voltage vs Capacity ===
figure; hold on;

% Charging
charge_start = find(diff([0; charge_idx]) == 1, 1, 'first');
charge_end = find(diff([charge_idx; 0]) == -1, 1, 'first');

if ~isempty(charge_start) && ~isempty(charge_end)
    idx = charge_start:charge_end;
    t_c = time(idx) - time(idx(1));
    v_c = voltage(idx);
    i_c = current(idx);
    cap_c = cumsum(abs(i_c) .* diff([0; t_c])) / 3.6;
    cap_c = cap_c - min(cap_c);
    plot(cap_c, v_c, '-', 'LineWidth', 2, 'DisplayName', 'Model Charging');
end

% Discharging
discharge_start = find(diff([0; discharge_idx]) == 1, 1, 'first');
discharge_end = find(diff([discharge_idx; 0]) == -1, 1, 'first');

if ~isempty(discharge_start) && ~isempty(discharge_end)
    idx = discharge_start:discharge_end;
    t_d = time(idx) - time(idx(1));
    v_d = voltage(idx);
    i_d = current(idx);
    cap_d = cumsum(i_d .* diff([0; t_d])) / 3.6;
    cap_d = cap_d - min(cap_d);
    plot(cap_d, v_d, '-', 'LineWidth', 2, 'DisplayName', 'Model Discharging');
end

% Experimental data
exp_data_path = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
exp_data = readtable(exp_data_path);
plot(exp_data.CapacityCby20_charge, exp_data.VoltageCby20_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental (Charge)');
plot(exp_data.CapacityCby20_discharge, exp_data.VoltageCby20_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental (Discharge)');

xlabel('Capacity / mA·h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on; hold off;

%% === FIGURE 2: Voltage vs Time ===
figure; hold on;

% Charge
t_charge = time(charge_idx) - time(find(charge_idx, 1, 'first'));
v_charge = voltage(charge_idx);
cv_limit = find(v_charge >= 3.47, 1);
if ~isempty(cv_limit)
    t_charge = t_charge(1:cv_limit);
    v_charge = v_charge(1:cv_limit);
end
plot(t_charge / 3600, v_charge, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');

% Discharge
t_discharge = time(discharge_idx) - time(find(discharge_idx, 1, 'first'));
v_discharge = voltage(discharge_idx);
plot(t_discharge / 3600, v_discharge, '-', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Model Discharge');

% Experimental Time Series
t_charge_exp = seconds(duration(exp_data.TimeCby20_charge));
t_discharge_exp = seconds(duration(exp_data.TimeCby20_discharge));
plot(t_charge_exp / 3600, exp_data.VoltageCby20_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental Charge');
plot(t_discharge_exp / 3600, exp_data.VoltageCby20_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental Discharge');

xlabel('Time / h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Time: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on; hold off;