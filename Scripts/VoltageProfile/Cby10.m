sweep = true;  % Set to true if you want to sweep multiple k0 values

% === Load Base JSON and Set Control Parameters ===
jsonstruct_base = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct_base.Control.initialControl = 'charging';
jsonstruct_base.Control.CRate = 0.1;
jsonstruct_base.Control.DRate = 0.1;
jsonstruct_base.Control.lowerCutoffVoltage = 2.9;
jsonstruct_base.Control.upperCutoffVoltage = 3.47;
jsonstruct_base.Control.dIdtLimit = 2e-10;
jsonstruct_base.Control.dEdtLimit = 2e-10;
jsonstruct_base.Control.numberOfCycles = 1;
jsonstruct_base.SOC = 0.01;

jsonstruct_base.TimeStepping.totalTime = 72000;
jsonstruct_base.TimeStepping.numberOfTimeSteps = 400;

jsonstruct_base.NegativeElectrode.Coating.thickness = jsonstruct_base.NegativeElectrode.Coating.thickness .* 0.94;
jsonstruct_base.PositiveElectrode.Coating.thickness = jsonstruct_base.PositiveElectrode.Coating.thickness .* 0.94;

jsonstruct_base.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
jsonstruct_base.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct_base.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct_base.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

% jsonstruct_base.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
jsonstruct_base.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 2.5e-12;

jsonstruct_base.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-13;
jsonstruct_base.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;

% Set base k0 for single-plot reference
k_base = 1e-10;
jsonstruct_base.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k_base;

% === Load Experimental Data ===
expFile = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Master/Dataset/24.02/Full_cell_0.1C.xlsx';
expTable = readtable(expFile, 'Sheet', 'Charge_Discharge');
expVoltage = expTable.Voltage;
expCapacity = expTable.Capacity;
expTime = seconds(duration(expTable.Time));

exp_start_charge = 100; exp_end_charge = 3258;
exp_start_discharge = 3272; exp_end_discharge = 6000;

expV_c = expVoltage(exp_start_charge:exp_end_charge);
expCap_c = expCapacity(exp_start_charge:exp_end_charge) - min(expCapacity(exp_start_charge:exp_end_charge));
expT_c = expTime(exp_start_charge:exp_end_charge) - expTime(exp_start_charge);

expV_d = expVoltage(exp_start_discharge:exp_end_discharge);
expCap_d = expCapacity(exp_start_discharge:exp_end_discharge) - min(expCapacity(exp_start_discharge:exp_end_discharge));
expT_d = expTime(exp_start_discharge:exp_end_discharge) - expTime(exp_start_discharge);

% === Run Simulation for Base k0 ===
output = runBatteryJson(jsonstruct_base);
states = output.states;

time = cellfun(@(s) s.time, states);
voltage = cellfun(@(s) s.Control.E, states);
current = cellfun(@(s) s.Control.I, states);

charge_idx = current < 0;
discharge_idx = current > 0;

charge_start = find(diff([0; charge_idx]) == 1, 1);
charge_end = find(diff([charge_idx; 0]) == -1, 1);
range_c = charge_start:charge_end;
t_c = time(range_c) - time(range_c(1));
v_c = voltage(range_c);
i_c = current(range_c);
cap_c = cumsum(abs(i_c .* diff([0; t_c]))) / 3.6;
cap_c = cap_c - min(cap_c);

discharge_start = find(diff([0; discharge_idx]) == 1, 1);
discharge_end = find(diff([discharge_idx; 0]) == -1, 1);
range_d = discharge_start:discharge_end;
t_d = time(range_d) - time(range_d(1));
v_d = voltage(range_d);
i_d = current(range_d);
cap_d = cumsum(i_d .* diff([0; t_d])) / 3.6;
cap_d = cap_d - min(cap_d);

% === Plot Voltage vs Capacity ===
figure; hold on;
plot(cap_c, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');
plot(cap_d, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharge');
plot(expCap_c, expV_c, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Exp Charge');
plot(expCap_d, expV_d, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Exp Discharge');
xlabel('Capacity / mA·h'); ylabel('Voltage / V');
title(['Voltage vs Capacity (k_0 = ', num2str(k_base), ')']);
legend('Location', 'best'); grid on; hold off;

% === Plot Voltage vs Time ===
figure; hold on;
plot(t_c / 3600, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');
plot(t_d / 3600, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharge');
plot(expT_c / 3600, expV_c, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Exp Charge');
plot(expT_d / 3600, expV_d, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Exp Discharge');
xlabel('Time / h'); ylabel('Voltage / V');
title(['Voltage vs Time (k_0 = ', num2str(k_base), ')']);
legend('Location', 'best'); grid on; hold off;

% === Optional Sweep ===
if sweep
    k_values = [5e-11, 7.5e-11, 1e-10, 1.25e-10, 1.5e-10];
    colors = lines(length(k_values));

    figure; hold on;
    for i = 1:length(k_values)
        jsonstruct = jsonstruct_base;
        jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k_values(i);
        output = runBatteryJson(jsonstruct);
        states = output.states;

        if isempty(states)
            warning(['Simulation failed for k = ', num2str(k_values(i))]);
            continue;
        end

        time = cellfun(@(s) s.time, states);
        voltage = cellfun(@(s) s.Control.E, states);
        current = cellfun(@(s) s.Control.I, states);

        charge_idx = current < 0;
        discharge_idx = current > 0;

        charge_start = find(diff([0; charge_idx]) == 1, 1);
        charge_end = find(diff([charge_idx; 0]) == -1, 1);
        if isempty(charge_start) || isempty(charge_end), continue; end
        t_c = time(charge_start:charge_end) - time(charge_start);
        v_c = voltage(charge_start:charge_end);
        i_c = current(charge_start:charge_end);
        cap_c = cumsum(abs(i_c .* diff([0; t_c]))) / 3.6;
        cap_c = cap_c - min(cap_c);

        discharge_start = find(diff([0; discharge_idx]) == 1, 1);
        discharge_end = find(diff([discharge_idx; 0]) == -1, 1);
        if isempty(discharge_start) || isempty(discharge_end), continue; end
        t_d = time(discharge_start:discharge_end) - time(discharge_start);
        v_d = voltage(discharge_start:discharge_end);
        i_d = current(discharge_start:discharge_end);
        cap_d = cumsum(i_d .* diff([0; t_d])) / 3.6;
        cap_d = cap_d - min(cap_d);

        plot(cap_c, v_c, '-', 'Color', colors(i,:), 'LineWidth', 2, ...
            'DisplayName', ['Charge, k = ', num2str(k_values(i))]);
        plot(cap_d, v_d, '--', 'Color', colors(i,:), 'LineWidth', 2, ...
            'DisplayName', ['Discharge, k = ', num2str(k_values(i))]);
    end

    % Plot Experimental on top
    plot(expCap_c, expV_c, ':', 'Color', [0.3 0.7 0.9], 'LineWidth', 2, 'DisplayName', 'Exp Charge');
    plot(expCap_d, expV_d, ':', 'Color', [0.9 0.7 0.1], 'LineWidth', 2, 'DisplayName', 'Exp Discharge');
    xlabel('Capacity / mA·h'); ylabel('Voltage / V');
    title('Voltage vs Capacity – Sweep of Negative Electrode k');
    legend('Location', 'best'); grid on; hold off;
end