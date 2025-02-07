% Load input configuration for the model
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters for the model
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';

% Run the model simulation
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract model data: time, voltage, and current
time = cellfun(@(state) state.time, states);
voltage = cellfun(@(state) state.Control.E, states);
current = cellfun(@(state) state.Control.I, states);

% Calculate the capacity from model data
capacity = flip(time .* -1 .* current);
model_capacity = capacity / (3600 * 1e-3); % Convert capacity to mAh

% Load experimental full-cell data
file_path_fullcell = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
experimental_data_fullcell = readtable(file_path_fullcell);
exp_voltage_fullcell = experimental_data_fullcell.VoltageCby20;
exp_capacity_fullcell = experimental_data_fullcell.CapacityCby20;

% Ensure alignment of model and experimental data
valid_indices = ~isnan(exp_voltage_fullcell) & ~isnan(exp_capacity_fullcell);
exp_capacity_fullcell = exp_capacity_fullcell(valid_indices);
exp_voltage_fullcell = exp_voltage_fullcell(valid_indices);

% Interpolate model voltage to match experimental capacity points
interp_model_voltage = interp1(model_capacity, voltage, exp_capacity_fullcell, 'linear', 'extrap');

% Remove NaN or Inf values from interpolated data
valid_interp_indices = ~isnan(interp_model_voltage) & ~isinf(interp_model_voltage);
interp_model_voltage = interp_model_voltage(valid_interp_indices);
exp_capacity_fullcell = exp_capacity_fullcell(valid_interp_indices);
exp_voltage_fullcell = exp_voltage_fullcell(valid_interp_indices);

% Calculate errors
absolute_error = abs(interp_model_voltage - exp_voltage_fullcell);
percentage_error = (absolute_error ./ exp_voltage_fullcell) * 100;
rmse = sqrt(mean((interp_model_voltage - exp_voltage_fullcell).^2)); % Root Mean Square Error
mape = mean(percentage_error); % Mean Absolute Percentage Error

% Find the point with the largest error
[max_error_absolute, max_error_idx] = max(absolute_error);
max_error_capacity = exp_capacity_fullcell(max_error_idx);
max_error_model_voltage = interp_model_voltage(max_error_idx);
max_error_percentage = percentage_error(max_error_idx);

% Select evenly spaced points for error bars (e.g., 6 points across the curve)
num_error_points = 20;
selected_indices = round(linspace(1, length(exp_capacity_fullcell), num_error_points));
selected_capacity = exp_capacity_fullcell(selected_indices);
selected_model_voltage = interp_model_voltage(selected_indices);
selected_absolute_error = absolute_error(selected_indices);
selected_percentage_error = percentage_error(selected_indices);

% Plot the discharge curve with selected error bars
figure(1); 
hold on;

% Plot experimental discharge curve (thin line)
plot(exp_capacity_fullcell, exp_voltage_fullcell, '-', 'LineWidth', 3, 'Color', 'r', 'DisplayName', 'Experimental');

% Plot model discharge curve (thin line)
plot(exp_capacity_fullcell, interp_model_voltage, '-', 'LineWidth', 3, 'Color', 'b', 'DisplayName', 'Model');

% Add error bars at selected points
errorbar(selected_capacity, selected_model_voltage, selected_absolute_error, 'k', ...
    'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 8, 'DisplayName', 'Error Bars');

% Highlight the point with the largest error
errorbar(max_error_capacity, max_error_model_voltage, max_error_absolute, 'r', ...
    'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10, 'DisplayName', 'Largest Error');

% Annotate error values at selected points
for i = 1:length(selected_indices)
    % Place annotations dynamically above or below the error bar
    text_offset = (-1)^i * 0.05; % Alternate above and below
    text(selected_capacity(i), selected_model_voltage(i) + text_offset, ...
        sprintf('%.2f%%', selected_percentage_error(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', 'black');
end

% Annotate the largest error point
text(max_error_capacity + 0.1, max_error_model_voltage + 0.2, ...
    sprintf('Max Error: %.2f%%', max_error_percentage), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'red');

% Annotate overall error metrics
overall_error_text = sprintf('RMSE: %.4f V\nMAPE: %.2f%%', rmse, mape);
text(2.5, 3.4, overall_error_text, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'black');

% Labels and legends
xlabel('Capacity / mA \cdot h', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 18, 'FontWeight', 'bold');
title('Discharge Curve with Errors', 'FontSize', 22, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 14);
grid on;

% Set tick label font size
ax = gca; % Get current axis
ax.FontSize = 14;
ax.FontWeight = 'bold';
hold off;

% Set figure size in pixels
figureHandle = gcf; % Get current figure handle
set(figureHandle, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen

set(figureHandle, 'PaperUnits', 'inches');
set(figureHandle, 'PaperSize', [16, 12]); % 16 inches wide and 12 inches tall
set(figureHandle, 'PaperPosition', [0, 0, 16, 12]); % Fill the entire page

%exportgraphics(gcf, '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/Errorplot.pdf', 'ContentType', 'vector', 'Resolution', 300);
