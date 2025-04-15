sweep = false;  % Set to true if you want to sweep multiple values

% === Load Base JSON and Set Control Parameters ===
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
jsonstruct.TimeStepping.numberOfTimeSteps = 400;

jsonstruct.NegativeElectrode.Coating.thickness = jsonstruct.NegativeElectrode.Coating.thickness .* 0.94;
jsonstruct.PositiveElectrode.Coating.thickness = jsonstruct.PositiveElectrode.Coating.thickness .* 0.94;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.04;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 2e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 2.5e-12;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-13;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;

% Set base for single-plot reference
D_base = 1e-13;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = D_base;

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

% === Run Simulation for Base value ===
output = runBatteryJson(jsonstruct);
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
title(['Voltage vs Capacity (D_0 = ', num2str(D_base), ')']);
legend('Location', 'best'); grid on; hold off;

% === Plot Voltage vs Time ===
figure; hold on;
plot(t_c / 3600, v_c, '-', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'Model Charge');
plot(t_d / 3600, v_d, '-', 'LineWidth', 2, 'Color', [0.850 0.325 0.098], 'DisplayName', 'Model Discharge');
plot(expT_c / 3600, expV_c, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Exp Charge');
plot(expT_d / 3600, expV_d, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Exp Discharge');
xlabel('Time / h'); ylabel('Voltage / V');
title(['Voltage vs Time (D_0 = ', num2str(D_base), ')']);
legend('Location', 'best'); grid on; hold off;

% === Optional Sweep ===
if sweep
    D_values = [5e-14, 2e-13, 1e-12, 1e-10, 1e-8];
    colors = lines(length(D_values));
    results = struct();  % Preallocate result struct array

    figure; hold on;

    for i = 1:length(D_values)
        disp(['Running sweep for D₀ = ', num2str(D_values(i))]);

        json_i = jsonstruct;  % Avoid modifying base struct
        json_i.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = D_values(i);

        output = runBatteryJson(json_i);
        states = output.states;

        if isempty(states)
            warning(['Simulation failed or returned empty for D = ', num2str(D_values(i))]);
            continue;
        end

        time = cellfun(@(s) s.time, states);
        voltage = cellfun(@(s) s.Control.E, states);
        current = cellfun(@(s) s.Control.I, states);

        charge_idx = current < 0;
        discharge_idx = current > 0;

        charge_start = find(diff([0; charge_idx]) == 1, 1);
        charge_end = find(diff([charge_idx; 0]) == -1, 1);
        discharge_start = find(diff([0; discharge_idx]) == 1, 1);
        discharge_end = find(diff([discharge_idx; 0]) == -1, 1);

        if isempty(charge_start) || isempty(charge_end) || charge_end <= charge_start || ...
           isempty(discharge_start) || isempty(discharge_end) || discharge_end <= discharge_start
            warning(['⚠️ Invalid charge/discharge range for D = ', num2str(D_values(i))]);
            continue;
        end

        range_c = charge_start:charge_end;
        t_c = time(range_c) - time(range_c(1));
        v_c = voltage(range_c);
        i_c = current(range_c);
        cap_c = cumsum(abs(i_c .* diff([0; t_c]))) / 3.6;
        cap_c = cap_c - min(cap_c);

        range_d = discharge_start:discharge_end;
        t_d = time(range_d) - time(range_d(1));
        v_d = voltage(range_d);
        i_d = current(range_d);
        cap_d = cumsum(i_d .* diff([0; t_d])) / 3.6;
        cap_d = cap_d - min(cap_d);

        % Store results
        results(i).D = D_values(i);
        results(i).cap_c = cap_c;
        results(i).v_c = v_c;
        results(i).cap_d = cap_d;
        results(i).v_d = v_d;

        % Plot
        plot(cap_c, v_c, '-', 'Color', colors(i,:), 'LineWidth', 2, ...
            'DisplayName', sprintf('Charge, D = %.1e', D_values(i)));
        plot(cap_d, v_d, '--', 'Color', colors(i,:), 'LineWidth', 2, ...
            'DisplayName', sprintf('Discharge, D = %.1e', D_values(i)));
    end

    % Plot Experimental on top
    plot(expCap_c, expV_c, ':', 'Color', [0.3 0.7 0.9], 'LineWidth', 2, 'DisplayName', 'Exp Charge');
    plot(expCap_d, expV_d, ':', 'Color', [0.9 0.7 0.1], 'LineWidth', 2, 'DisplayName', 'Exp Discharge');

    xlabel('Capacity / mA·h'); ylabel('Voltage / V');
    title('Voltage vs Capacity – Sweep of Positive Electrode D');
    legend('Location', 'best'); grid on; hold off;
end