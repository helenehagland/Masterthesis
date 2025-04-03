% === Load JSON and Set Control Parameters ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct.Control.initialControl = 'discharging';
jsonstruct.Control.CRate = 0.3;
jsonstruct.Control.DRate = 0.3;
jsonstruct.Control.lowerCutoffVoltage = 2.9;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.SOC = 0.95;

jsonstruct.TimeStepping.totalTime = 12000; % Adjust if needed for slower rate
jsonstruct.TimeStepping.numberOfTimeSteps = 1200;
jsonstruct.Control.dEdtLimit = 1e-2;
jsonstruct.Control.dIdtLimit = 1e-2;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-11;

% === Run Simulation ===
output = runBatteryJson(jsonstruct);
states = output.states;

time = cellfun(@(s) s.time, states);
voltage = cellfun(@(s) s.Control.E, states);
current = cellfun(@(s) s.Control.I, states);

charge_idx = current < 0;
discharge_idx = current > 0;

charge_end_idxs = find(diff([charge_idx; 0]) == -1);
discharge_starts = find(diff([0; discharge_idx]) == 1);
discharge_ends = find(diff([discharge_idx; 0]) == -1);

num_cycles = min(jsonstruct.Control.numberOfCycles, 5);

% === Load Experimental Data ===
expfile = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Master/Dataset/24.02/Full_cell_0.3C.xlsx';
expdata = readtable(expfile, 'Sheet', 'Charge_Discharge');
exp_voltage = expdata.Voltage;
exp_capacity = expdata.Capacity;
exp_time = hours(duration(expdata.Time, 'InputFormat', 'hh:mm:ss'));

% === FIGURE 1: Voltage vs Capacity ===
figure; hold on;

for cycle = 1:num_cycles
    % Charging
    charge_start = find(diff([0; charge_idx]) == 1, cycle, 'first');
    if length(charge_end_idxs) >= cycle
        charge_end = charge_end_idxs(cycle);
        range_c = charge_start:charge_end;
        t_c = time(range_c) - time(range_c(1));
        v_c = voltage(range_c);
        i_c = current(range_c);
        cap_c = cumsum(abs(i_c) .* diff([0; t_c])) / 3.6;
        cap_c = cap_c - min(cap_c);
        plot(cap_c, v_c, '-', 'LineWidth', 2, 'DisplayName', ['Model Charge Cycle ', num2str(cycle)]);
    end

    % Discharging
    if length(discharge_starts) >= cycle && length(discharge_ends) >= cycle
        discharge_start = discharge_starts(cycle);
        discharge_end = discharge_ends(cycle);
        range_d = discharge_start:discharge_end;
        t_d = time(range_d) - time(range_d(1));
        v_d = voltage(range_d);
        i_d = current(range_d);
        cap_d = cumsum(i_d .* diff([0; t_d])) / 3.6;
        cap_d = cap_d - min(cap_d);
        plot(cap_d, v_d, '-', 'LineWidth', 2, 'DisplayName', ['Model Discharge Cycle ', num2str(cycle)]);
    end
end

plot(exp_capacity, exp_voltage, '--', 'LineWidth', 2, 'Color', [0.5 0.7 0.9], 'DisplayName', 'Experimental (1C)');

xlabel('Capacity / mA·h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Capacity: Model vs Experimental (1C)', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% === FIGURE 2: Voltage vs Time ===
figure; hold on;

% Charge
time_charge = time(charge_idx);
voltage_charge = voltage(charge_idx);
time_charge = time_charge - time_charge(1);
plot(time_charge / 3600, voltage_charge, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');


time_discharge = time(discharge_idx);
voltage_discharge = voltage(discharge_idx);
time_discharge = time_discharge - time_discharge(1);
plot(time_discharge / 3600, voltage_discharge, '-', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Model Discharge');

% Experimental
plot(exp_time, exp_voltage, '--', 'LineWidth', 2, 'Color', [0.5 0.7 0.9], 'DisplayName', 'Experimental (1C)');

xlabel('Time / h', 'FontSize', 14);
ylabel('Voltage / V', 'FontSize', 14);
title('Voltage vs Time: Model vs Experimental (1C)', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

figure;
plot(time / 3600, current);
xlabel('Time / h'); ylabel('Current / A');
title('Current vs Time');
grid on;