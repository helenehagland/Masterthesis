% === SETUP: Load JSON and Control Parameters ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.CRate = 0.1;
jsonstruct.Control.DRate = 0.1;
jsonstruct.Control.lowerCutoffVoltage = 2.9;
jsonstruct.Control.upperCutoffVoltage = 3.47;
jsonstruct.Control.dIdtLimit = 2e-10;
jsonstruct.Control.dEdtLimit = 2e-10;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.SOC = 0.01;

jsonstruct.TimeStepping.totalTime = 72000;
jsonstruct.TimeStepping.numberOfTimeSteps = 144000;

% Electrode properties
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-11;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-13;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;

% === Run Simulation ===
output = runBatteryJson(jsonstruct);
states = output.states;

% === Extract Simulation Data ===
time = cellfun(@(s) s.time, states);               % [s]
voltage = cellfun(@(s) s.Control.E, states);       % [V]
current = cellfun(@(s) s.Control.I, states);       % [A]

% === Detect Charge and Discharge Ranges ===
charge_idx = current < 0;
discharge_idx = current > 0;

% Charging
charge_start = find(diff([0; charge_idx]) == 1, 1);
charge_end = find(diff([charge_idx; 0]) == -1, 1);
range_c = charge_start:charge_end;
t_c = time(range_c) - time(range_c(1));
v_c = voltage(range_c);
i_c = current(range_c);
dt_c = diff([0; t_c]);
cap_c = cumsum(abs(i_c) .* dt_c) / 3.6;
cap_c = cap_c - min(cap_c);

% Discharging
discharge_start = find(diff([0; discharge_idx]) == 1, 1);
discharge_end = find(diff([discharge_idx; 0]) == -1, 1);
range_d = discharge_start:discharge_end;
t_d = time(range_d) - time(range_d(1));
v_d = voltage(range_d);
i_d = current(range_d);
dt_d = diff([0; t_d]);
cap_d = cumsum(i_d .* dt_d) / 3.6;
cap_d = cap_d - min(cap_d);

% === Load Experimental Data ===
expFile = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Master/Dataset/24.02/Full_cell_0.1C.xlsx';
expTable = readtable(expFile, 'Sheet', 'Charge_Discharge');
expVoltage = expTable.Voltage;
expCapacity = expTable.Capacity;
expTime = seconds(duration(expTable.Time));

% === MANUAL SLICING: updated based on Excel inspection ===
exp_start_charge = 100;       % or earlier, depending on data start
exp_end_charge = 3258;
exp_start_discharge = 3272;
exp_end_discharge = 6000;     % or last row of your dataset

% === Slice Experimental Charge ===
expV_c = expVoltage(exp_start_charge:exp_end_charge);
expCap_c = expCapacity(exp_start_charge:exp_end_charge);
expT_c = expTime(exp_start_charge:exp_end_charge);
expCap_c = expCap_c - min(expCap_c);
expT_c = expT_c - min(expT_c);  % ✅ fix: avoids negative time

% === Slice Experimental Discharge ===
expV_d = expVoltage(exp_start_discharge:exp_end_discharge);
expCap_d = expCapacity(exp_start_discharge:exp_end_discharge);
expT_d = expTime(exp_start_discharge:exp_end_discharge);
expCap_d = expCap_d - min(expCap_d);
expT_d = expT_d - min(expT_d);  % ✅ fix: avoids negative time

% === Plot: Voltage vs Capacity ===
figure;
hold on;
plot(cap_c, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charging');
plot(cap_d, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharging');
plot(expCap_c, expV_c, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental Charge');
plot(expCap_d, expV_d, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental Discharge');
xlabel('Capacity / mA·h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best');
grid on;
hold off;

% === Plot: Voltage vs Time ===
figure;
hold on;
plot(t_c / 3600, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');
plot(t_d / 3600, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharge');
plot(expT_c / 3600, expV_c, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental Charge');
plot(expT_d / 3600, expV_d, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental Discharge');
xlabel('Time / h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Time: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best');
grid on;
hold off;