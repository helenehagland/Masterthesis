% **Plotting Options** 
plotCharge = true;     % Set to true if you want to plot charging
plotDischarge = true;  % Set to true if you want to plot discharging

% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% **Debug: Check guestStoichiometry0 Value**
disp(['Loaded guestStoichiometry0: ', num2str(jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.guestStoichiometry0)]);

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 2.5;
jsonstruct.Control.upperCutoffVoltage = 4.5;

% Start with charging and simulate the full curve
jsonstruct.Control.initialControl = 'charging';

% Run simulation and store results
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% **Debug: Check Voltage Range After Simulation**
disp(['Voltage range (Overall): ', num2str(min(voltage)), ' to ', num2str(max(voltage)), ' V']);

% **Split into Charging and Discharging Phases**
charge_idx = current < 0;  % Negative current = charging
discharge_idx = current > 0;  % Positive current = discharging

% **Calculate Capacity for Charging and Discharging Separately**
% Charging Capacity
if plotCharge
    dt_charge = diff([0; time(charge_idx)]);
    capacity_charge = cumsum(current(charge_idx) .* dt_charge) / 3.6;
    capacity_charge = capacity_charge - min(capacity_charge); % Normalize to start at zero
    capacity_charge = max(capacity_charge) - capacity_charge; % Flip charging curve
end

% **Discharging Capacity**
if plotDischarge
    % Find the first discharge index
    discharge_start_idx = find(current > 0, 1, 'first'); % First index where current is positive (discharging)

    % Ensure we only plot discharge
    if ~isempty(discharge_start_idx)
        time_discharge = time(discharge_start_idx:end) - time(discharge_start_idx); % Normalize time to start at zero
        voltage_discharge = voltage(discharge_start_idx:end);
        current_discharge = current(discharge_start_idx:end);

        % **Stop condition for voltage below 2.5V**
        lower_cutoff = 2.5;
        stop_idx = find(voltage_discharge < lower_cutoff, 1, 'first'); % Find first index below cutoff

        % **Debug: Check if Voltage Goes Below 2.5V During Discharge**
        disp(['Minimum voltage during discharge: ', num2str(min(voltage_discharge))]);

        if ~isempty(stop_idx)
            % Limit data to stop at the cutoff voltage
            time_discharge = time_discharge(1:stop_idx);
            voltage_discharge = voltage_discharge(1:stop_idx);
            current_discharge = current_discharge(1:stop_idx);
        end

        % Correct capacity calculation
        dt_discharge = diff([0; time_discharge]); % Time step differences
        capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6; % Convert to mAh
        capacity_discharge = capacity_discharge - min(capacity_discharge); % Ensure it starts at zero
    end
end

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';

if plotCharge
    % Load only charging data
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
    exp_capacity_charge = experimental_data_fullcell.CapacityCby20_charge;
    exp_label_charge = 'Experimental (Charge Only)';
end

if plotDischarge
    % Load only discharging data
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
    exp_capacity_discharge = experimental_data_fullcell.CapacityCby20_discharge;
    exp_label_discharge = 'Experimental (Discharge Only)';
end

% **Plot Full Model Curve vs Experimental Data**
figure;
hold on;

% **Plot Model Data**
if plotCharge
    plot(capacity_charge, voltage(charge_idx), '-', 'LineWidth', 3, 'Color', [0 0.447 0.741], 'DisplayName', 'Model Charging');
end

if plotDischarge
    plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 3, 'Color', [0.85 0.325 0.098], 'DisplayName', 'Model Discharging');
end

% **Plot Experimental Data**
if plotCharge
    plot(exp_capacity_charge, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', exp_label_charge);
end

if plotDischarge
    plot(exp_capacity_discharge, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', exp_label_discharge);
end

% **Label Plot**
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% **Debugging Output**
if plotDischarge
    disp(['Discharge starts at timestep: ', num2str(discharge_start_idx)]);
    disp(['Voltage range (Discharge): ', num2str(min(voltage_discharge)), ' to ', num2str(max(voltage_discharge)), ' V']);
    disp(['Capacity range (Model - Discharge): ', num2str(min(capacity_discharge)), ' to ', num2str(max(capacity_discharge)), ' mAh']);
end
if plotCharge
    disp(['Charging Capacity range (Model): ', num2str(min(capacity_charge)), ' to ', num2str(max(capacity_charge)), ' mAh']);
end