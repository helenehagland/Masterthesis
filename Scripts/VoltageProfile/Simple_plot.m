jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');
%jsonstruct = parseBattmoJson('Documents/MATLAB/Software/BattMo/Examples/JsonDataFiles/sample_input.json');




% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';
disp(jsonstruct.Control)
output = runBatteryJson(jsonstruct);
states = output.states;


x = output.model.grid.cells.centroids;
% x_ne = output.model.NegativeElectrode.Coating.G.cel;
% x_pe = 
c = output.states{end}.Electrolyte.c;
c_ne = output.states{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
c_pe = output.states{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
phi = output.states{end}.Electrolyte.phi;
phi_ne = output.states{end}.NegativeElectrode.Coating.phi;
phi_pe= output.states{end}.PositiveElectrode.Coating.phi;

% Subplots for concentration and potential
figure(1);
subplot(2, 3, 1);
plot(c_ne, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Concentration / mol · L^{-1}');
title('Negative Electrode Concentration');

subplot(2, 3, 2);
plot(x, c, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Concentration / mol · L^{-1}');
title('Electrolyte Concentration');

subplot(2, 3, 3);
plot(c_pe, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Concentration / mol · L^{-1}');
title('Positive Electrode Concentration');

subplot(2, 3, 4);
plot(phi_ne, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Potential / V');
title('Negative Electrode Potential');

subplot(2, 3, 5);
plot(x, phi, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Potential / V');
title('Electrolyte Potential');

subplot(2, 3, 6);
plot(phi_pe, 'LineWidth', 3);
xlabel('Position / m');
ylabel('Potential / V');
title('Positive Electrode Potential');


figure(2);

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.('Control').E, states);
current = cellfun(@(state) state.('Control').I, states);

% Calculate the capacity from model data
capacity = time .* -1.*current;

% Plot the model discharge curve
plot((flip(capacity) / (3600 * 1e-3)), voltage, '-', 'LineWidth', 3, 'MarkerSize', 5,'DisplayName', 'Model') % Convert to mA·h
hold on


plot_experimental = true;
if plot_experimental
    % Load and extract the experimental data for full cell
    file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
    experimental_data_fullcell = readtable(file_path_fullcell);
    exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
    exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;
    
    % Load and extract the experimental data for LNMO
    file_path_lnmo = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_LNMO_RCHL374.xlsx';
    experimental_data_lnmo = readtable(file_path_lnmo, 'Sheet', 'Voltage_Capacity');
    exp_voltage_lnmo = experimental_data_lnmo.Voltage;
    exp_capacity_lnmo = experimental_data_lnmo.Capacity;
    
    % Load and extract the experimental data for XNO
    file_path_xno = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_XNO_RCHX143.xlsx';
    experimental_data_xno = readtable(file_path_xno, 'Sheet', 'Voltage_Capacity');
    exp_voltage_xno = experimental_data_xno.Voltage;
    exp_capacity_xno = experimental_data_xno.Capacity;
    exp_voltage_xno = flip(exp_voltage_xno);
    exp_capacity = flip(exp_capacity_xno);

    
    % Plot the experimental voltage vs. capacity data for each dataset
    plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'Full cell')
    hold on
    plot(exp_capacity_lnmo, exp_voltage_lnmo, 's-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'LNMO')
    plot(exp_capacity_xno, exp_voltage_xno, '^-', 'LineWidth', 2, 'MarkerSize', 2, 'DisplayName', 'XNO')
end

% Label the plot
xlabel('Capacity / mA \cdot h')
ylabel('Voltage / V')
legend('Location', 'best')
grid on
hold off
