% === SETUP: Load JSON and Control Parameters ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.CRate = 0.01;
jsonstruct.Control.DRate = 0.01;
jsonstruct.Control.lowerCutoffVoltage = 2.9;
jsonstruct.Control.upperCutoffVoltage = 3.47;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.SOC = 0.01;


jsonstruct.TimeStepping.totalTime = 750000;
jsonstruct.TimeStepping.numberOfTimeSteps = 75000;

% Electrode and interface properties
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

% === Charging Phase ===
charge_idx = find(current < 0);
t_c = time(charge_idx) - time(charge_idx(1));
v_c = voltage(charge_idx);
i_c = current(charge_idx);
dt_c = diff([0; t_c]);
cap_c = cumsum(abs(i_c) .* dt_c) / 3.6;
cap_c = cap_c - min(cap_c);

% === Discharging Phase (chronological time & capacity) ===
discharge_idx = find(current > 0);
if ~isempty(discharge_idx)
    t_d = time(discharge_idx);  % Absolute time
    v_d = voltage(discharge_idx);
    i_d = current(discharge_idx);
    dt_d = diff([0; t_d - t_d(1)]);
    cap_d = cumsum(i_d .* dt_d) / 3.6 + cap_c(end);  % Continue capacity from end of charge
else
    warning('No discharge steps found.');
    t_d = []; v_d = []; i_d = []; cap_d = [];
end

% === Plot: Voltage vs Capacity ===
figure;
hold on;
plot(cap_c, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charging');
plot(cap_d, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharging');
xlabel('Capacity / mA·h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Capacity (C/100)', 'FontSize', 16);
legend('Location', 'best');
grid on;
hold off;

% === Plot: Voltage vs Time ===
figure;
hold on;
plot(t_c / 3600, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');
plot(t_d / 3600, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharge');
xlabel('Time / h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Time (C/100)', 'FontSize', 16);
legend('Location', 'best');
grid on;
hold off;

% === EXTRA PLOT: Chronological Voltage vs Time ===
time_hr = time / 3600;
figure;
plot(time_hr, voltage, 'b-', 'LineWidth', 2);
xlabel('Time / h');
ylabel('Voltage / V');
title('Voltage vs Time (Chronological)');
grid on;

% === EXTRA PLOT: Voltage vs Capacity with Cumulative Signed Capacity ===
dt = diff([0; time]);
signed_capacity = cumsum(current .* dt) / 3.6;  % mA·h

figure; hold on;
plot(signed_capacity(current < 0), voltage(current < 0), 'b-', 'LineWidth', 2, 'DisplayName', 'Charge');
plot(signed_capacity(current > 0), voltage(current > 0), 'r-', 'LineWidth', 2, 'DisplayName', 'Discharge');
xlabel('Capacity / mA·h'); ylabel('Voltage / V');
title('Voltage vs Capacity (C/100, Chronological)');
legend; grid on;