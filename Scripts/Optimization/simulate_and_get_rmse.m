function rmse_total = simulate_and_get_rmse(neg_thickness, pos_thickness, showPlot)
    if nargin < 3
        showPlot = true;
    end

%% === Load Input Configuration ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% --- Control settings ---
jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 2.5;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.dIdtLimit = 5e-7;
jsonstruct.Control.dEdtLimit = 1e-5;
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.SOC = 0.01;

% --- Time settings ---
jsonstruct.TimeStepping.numberOfTimeSteps = 400;

% --- Custom parameter overwrite ---
jsonstruct.NegativeElectrode.Coating.thickness = neg_thickness;
jsonstruct.PositiveElectrode.Coating.thickness = pos_thickness;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.01;
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.8;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0 = 0.86;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry100 = 0.015;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1.5e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 2.5e-12;

jsonstruct.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-13;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;

%% === Run Simulation ===
try
    output = runBatteryJson(jsonstruct);
catch
    warning('Simulation failed — returning large RMSE');
    rmse_total = 1000;
    return;
end
states = output.states;

% === Extract Model Data ===
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

charge_idx = current < 0;
discharge_idx = current > 0;

% === Diagnostic check ===
fprintf('Charge points: %d\n', sum(charge_idx));
fprintf('Discharge points: %d\n', sum(discharge_idx));

% Capacity calculation
cap_model = cumsum(abs(current) .* [0; diff(time)]) / 3.6;

% Separate charge/discharge segments
cap_model_charge = cap_model(charge_idx);
v_model_charge = voltage(charge_idx);

cap_model_discharge = cap_model(discharge_idx);
v_model_discharge = voltage(discharge_idx);

% === Fix 1: Normalize discharge capacity to start at zero
cap_model_discharge = cap_model_discharge - min(cap_model_discharge);

% === Fix 2: Trim tail of charge curve after voltage peak (usually where CV phase ends)
[~, peak_idx] = max(v_model_charge);  % Find where voltage peaks during charge
cap_model_charge = cap_model_charge(1:peak_idx);
v_model_charge = v_model_charge(1:peak_idx);

%% === Experimental Data ===
exp_data_path = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
exp_data = readtable(exp_data_path);

cap_exp_charge = exp_data.CapacityCby20_charge;
v_exp_charge   = exp_data.VoltageCby20_charge;

valid_charge = ~isnan(cap_exp_charge) & ~isnan(v_exp_charge);
cap_exp_charge = cap_exp_charge(valid_charge);
v_exp_charge   = v_exp_charge(valid_charge);

cap_exp_discharge = exp_data.CapacityCby20_discharge;
v_exp_discharge   = exp_data.VoltageCby20_discharge;

valid_discharge = ~isnan(cap_exp_discharge) & ~isnan(v_exp_discharge);
cap_exp_discharge = cap_exp_discharge(valid_discharge);
v_exp_discharge   = v_exp_discharge(valid_discharge);

%% === Interpolate Experimental Data ===
v_exp_c_interp = interp1(cap_exp_charge, v_exp_charge, cap_model_charge, 'linear', 'extrap');
v_exp_d_interp = interp1(cap_exp_discharge, v_exp_discharge, cap_model_discharge, 'linear', 'extrap');

%% === RMSE Calculation ===
rmse_charge = sqrt(mean((v_model_charge - v_exp_c_interp).^2));
rmse_discharge = sqrt(mean((v_model_discharge - v_exp_d_interp).^2));
rmse_total = sqrt(mean([ ...
    (v_model_charge - v_exp_c_interp).^2; ...
    (v_model_discharge - v_exp_d_interp).^2 ...
]));

%% === Plotting (only if showPlot is true) ===
if showPlot
    figure; hold on;
    plot(cap_model_charge, v_model_charge, '-', 'LineWidth', 2, 'DisplayName', 'Model Charge');
    plot(cap_model_discharge, v_model_discharge, '-', 'LineWidth', 2, 'DisplayName', 'Model Discharge');
    plot(cap_exp_charge, v_exp_charge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Charge');
    plot(cap_exp_discharge, v_exp_discharge, '--', 'LineWidth', 2, 'DisplayName', 'Experimental Discharge');
    xlabel('Capacity (mA·h)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
    legend('Location', 'best');
    grid on;
    
    text(0.1, 3.52, sprintf('RMSE Charge: %.4f V', rmse_charge), 'FontSize', 12);
    text(0.1, 3.46, sprintf('RMSE Discharge: %.4f V', rmse_discharge), 'FontSize', 12);
    text(0.1, 3.40, sprintf('RMSE Total: %.4f V', rmse_total), 'FontSize', 12);
    hold off;
end

end