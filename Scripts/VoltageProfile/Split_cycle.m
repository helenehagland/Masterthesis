% Load experimental data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data = readtable(file_path_fullcell);

% === Define j0 as a function of SOC for positive electrode
% json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.exchangeCurrentDensity.type = 'function';
% json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.exchangeCurrentDensity.functionname = 'computeJ0_LNMO_Morrow';
% json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.exchangeCurrentDensity.argumentlist = ["cElectrodeSurface"];

% ===== CHARGE ONLY SIMULATION =====
json_charge = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');
json_charge.Control.initialControl = 'charging';
json_charge.Control.CRate = 0.05;
json_charge.Control.DRate = 0.05;
json_charge.Control.lowerCutoffVoltage = 2.5;
json_charge.Control.upperCutoffVoltage = 3.47;
json_charge.Control.dIdtLimit = 2e-6;
json_charge.Control.dEdtLimit = 2e-6;
json_charge.Control.numberOfCycles = 1;
json_charge.SOC = 0.01;

% Overwrite parameter values (same for both)
json_charge.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
json_charge.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;
json_charge.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-11;
json_charge.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 9e-13;

% === Run charge simulation ===
output_charge = runBatteryJson(json_charge);
states_charge = output_charge.states;
time = cellfun(@(s) s.time, states_charge);
voltage = cellfun(@(s) s.Control.E, states_charge);
current = cellfun(@(s) s.Control.I, states_charge);

% === Plot Charge: Voltage vs Capacity ===
figure;
charge_idx = current < 0;
time_charge = time(charge_idx) - time(find(charge_idx, 1));
voltage_charge = voltage(charge_idx);
current_charge = current(charge_idx);
dt_charge = diff([0; time_charge]);
capacity_charge = cumsum(abs(current_charge) .* dt_charge) / 3.6;
capacity_charge = capacity_charge - min(capacity_charge);

% === Trim resting phase after charge ===
cutoff_charge_idx = find(voltage_charge >= 3.47, 1, 'first');
current_flip_idx_charge = find(current_charge >= 0, 1, 'first');
cutoff_idx_charge = min([cutoff_charge_idx, current_flip_idx_charge], [], 'omitnan');

if ~isempty(cutoff_idx_charge)
    time_charge = time_charge(1:cutoff_idx_charge);
    voltage_charge = voltage_charge(1:cutoff_idx_charge);
    current_charge = current_charge(1:cutoff_idx_charge);
    capacity_charge = capacity_charge(1:cutoff_idx_charge);
end
plot(capacity_charge, voltage_charge, '-', 'LineWidth', 2, 'DisplayName', 'Model Charge');
hold on;
plot(experimental_data.CapacityCby20_charge, experimental_data.VoltageCby20_charge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Charge');
xlabel('Capacity / mA·h'); ylabel('Voltage / V'); title('Charge: Voltage vs Capacity');
legend; grid on;

% === Plot Charge: Voltage vs Time ===
figure;
plot(time_charge / 3600, voltage_charge, '-', 'LineWidth', 2, 'DisplayName', 'Model Charge');
hold on;
time_exp_charge_sec = seconds(duration(experimental_data.TimeCby20_charge));
plot(time_exp_charge_sec / 3600, experimental_data.VoltageCby20_charge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Charge');
xlabel('Time / h'); ylabel('Voltage / V'); title('Charge: Voltage vs Time');
legend; grid on;

% ===== DISCHARGE ONLY SIMULATION =====
json_discharge = json_charge;
json_discharge.Control.initialControl = 'discharging';
json_discharge.SOC = 0.995;  % or higher starting SOC for discharge

% === Run discharge simulation ===
output_discharge = runBatteryJson(json_discharge);
states_discharge = output_discharge.states;
time = cellfun(@(s) s.time, states_discharge);
voltage = cellfun(@(s) s.Control.E, states_discharge);
current = cellfun(@(s) s.Control.I, states_discharge);

% === Plot Discharge: Voltage vs Capacity ===
figure;
discharge_idx = current > 0;
time_discharge = time(discharge_idx) - time(find(discharge_idx, 1));
voltage_discharge = voltage(discharge_idx);
current_discharge = current(discharge_idx);
dt_discharge = diff([0; time_discharge]);
capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
capacity_discharge = capacity_discharge - min(capacity_discharge);

% === Trim resting phase after discharge ===
cutoff_discharge_idx = find(voltage_discharge <= 2.5, 1, 'first');
current_flip_idx_discharge = find(current_discharge <= 0, 1, 'first');
cutoff_idx_discharge = min([cutoff_discharge_idx, current_flip_idx_discharge], [], 'omitnan');

if ~isempty(cutoff_idx_discharge)
    time_discharge = time_discharge(1:cutoff_idx_discharge);
    voltage_discharge = voltage_discharge(1:cutoff_idx_discharge);
    current_discharge = current_discharge(1:cutoff_idx_discharge);
    capacity_discharge = capacity_discharge(1:cutoff_idx_discharge);
end
plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 2, 'DisplayName', 'Model Discharge');
hold on;
plot(experimental_data.CapacityCby20_discharge, experimental_data.VoltageCby20_discharge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Discharge');
xlabel('Capacity / mA·h'); ylabel('Voltage / V'); title('Discharge: Voltage vs Capacity');
legend; grid on;

% === Plot Discharge: Voltage vs Time ===
figure;
plot(time_discharge / 3600, voltage_discharge, '-', 'LineWidth', 2, 'DisplayName', 'Model Discharge');
hold on;
time_exp_discharge_sec = seconds(duration(experimental_data.TimeCby20_discharge));
plot(time_exp_discharge_sec / 3600, experimental_data.VoltageCby20_discharge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Discharge');
xlabel('Time / h'); ylabel('Voltage / V'); title('Discharge: Voltage vs Time');
legend; grid on;