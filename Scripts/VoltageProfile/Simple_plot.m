% **Plotting Options** 
plotCharge = true;    
plotDischarge = true;  

% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 2.5;  % Lower cutoff voltage to extend discharge
jsonstruct.Control.upperCutoffVoltage = 4.2;
jsonstruct.Control.dIdtLimit = 0.01;  
jsonstruct.Control.dEdtLimit = 0.01;  

% Start with charging
jsonstruct.Control.initialControl = 'charging';
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current for charging
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% **Calculate Capacity for Charging**
dt_charge = diff([0; time]);
capacity_charge = cumsum(current .* dt_charge) / 3.6;
capacity_charge = capacity_charge - min(capacity_charge); 
capacity_charge = max(capacity_charge) - capacity_charge; 

% **Switch to Discharge after Charging**
jsonstruct.Control.initialControl = 'discharging';
jsonstruct.SOC = 1;  % Ensure full SOC for discharge

% Run simulation for discharging
output_discharge = runBatteryJson(jsonstruct);
states_discharge = output_discharge.states;

% Extract model data for discharging
time_discharge = cellfun(@(state) state.time, states_discharge);
voltage_discharge = cellfun(@(state) state.Control.E, states_discharge);
current_discharge = cellfun(@(state) state.Control.I, states_discharge);

% **Calculate Capacity for Discharging**
dt_discharge = diff([0; time_discharge]);
capacity_discharge = cumsum(current_discharge .* dt_discharge) / 3.6;
capacity_discharge = capacity_discharge - min(capacity_discharge); 

% **Load Experimental Data**
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);

% **Use Separate Experimental Data for Charge and Discharge**
exp_voltage_charge = experimental_data_fullcell.VoltageCby20_charge;
exp_capacity_charge = experimental_data_fullcell.CapacityCby20_charge;
exp_voltage_discharge = experimental_data_fullcell.VoltageCby20_discharge;
exp_capacity_discharge = experimental_data_fullcell.CapacityCby20_discharge;

% **Plot Full Model Curve vs Experimental Data**
figure; hold on;

% **Plot Model Data**
plot(capacity_charge, voltage, '-', 'LineWidth', 3, 'Color', [0 0.447 0.741], 'DisplayName', 'Model Charging');
plot(capacity_discharge, voltage_discharge, '-', 'LineWidth', 3, 'Color', [0.85 0.325 0.098], 'DisplayName', 'Model Discharging');

% **Plot Experimental Data (Separate Charge & Discharge)**
plot(exp_capacity_charge, exp_voltage_charge, '--', 'LineWidth', 2, 'Color', [0.301 0.745 0.933], 'DisplayName', 'Experimental Charging');
plot(exp_capacity_discharge, exp_voltage_discharge, '--', 'LineWidth', 2, 'Color', [0.929 0.694 0.125], 'DisplayName', 'Experimental Discharging');

% **Label Plot**
xlabel('Capacity / mA \cdot h', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 14, 'FontWeight', 'bold');
title('Voltage vs Capacity: Model vs Experimental', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% **Debugging Output**
disp(['Voltage range (Discharge): ', num2str(min(voltage_discharge)), ' to ', num2str(max(voltage_discharge)), ' V']);
disp(['Capacity range (Model - Discharge): ', num2str(min(capacity_discharge)), ' to ', num2str(max(capacity_discharge)), ' mAh']);
disp(['Charging Capacity range (Model): ', num2str(min(capacity_charge)), ' to ', num2str(max(capacity_charge)), ' mAh']);