% Opt_dummy.m
clear; close all; clc;

%% === Load Experimental Data ===
exp_data_path = '/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx';
exp_data = readtable(exp_data_path);

capacity_exp = exp_data.CapacityCby20_discharge;
voltage_exp = exp_data.VoltageCby20_discharge;

valid_idx = ~isnan(capacity_exp) & ~isnan(voltage_exp);
capacity_exp = capacity_exp(valid_idx);
voltage_exp = voltage_exp(valid_idx);

cap_common = linspace(min(capacity_exp), max(capacity_exp), 500);
voltage_exp_interp = interp1(capacity_exp, voltage_exp, cap_common, 'linear', 'extrap');

%% === Define Flexible Dummy Model ===
model_fun = @(p, cap) p(1) - log(1 + p(2) * cap) + p(3) * cap + p(4) * cap.^2;
params_initial = [3.5, 0.4, 0, 0];  % [a, b, c, d]
step_history = [];  % to store optimization steps

% Initial dummy voltage and RMSE
dummy_voltage = model_fun(params_initial, cap_common);
rmse_init = sqrt(mean((voltage_exp_interp - dummy_voltage).^2));

%% === Figure 1: Initial Fit ===
figure; hold on;
plot(capacity_exp, voltage_exp, '--', 'LineWidth', 2, 'DisplayName', 'Experimental');
plot(cap_common, dummy_voltage, '-', 'LineWidth', 2, 'DisplayName', 'Initial Model');
xlabel('Capacity / mA·h'); ylabel('Voltage / V');
title(sprintf('Figure 1: Initial Fit (RMSE = %.3f V)', rmse_init), 'FontWeight', 'bold');
legend('Location', 'best'); grid on;

%% === Brute Force Cost Landscape (a vs b) ===
a_vals = linspace(3, 4, 50);
b_vals = linspace(0.01, 1.5, 50);
RMSE_map = zeros(length(a_vals), length(b_vals));

for i = 1:length(a_vals)
    for j = 1:length(b_vals)
        temp_params = [a_vals(i), b_vals(j), 0, 0];  % Set c=d=0 for landscape
        model_v = model_fun(temp_params, cap_common);
        RMSE_map(i, j) = sqrt(mean((voltage_exp_interp - model_v).^2));
    end
end

%% === Figure 2: Brute Force Cost Landscape (No Steps) ===
figure;
contourf(b_vals, a_vals, RMSE_map, 30); colorbar;
xlabel('Parameter b'); ylabel('Parameter a');
title('Figure 2: Brute Force Cost Landscape (RMSE)');

%% === Optimization with fminsearch ===
% Define objective function that logs steps
objectiveFun = @(p) storeStep(p, cap_common, voltage_exp_interp, model_fun);

% Reset global history
clear global step_history;
global step_history;
step_history = [];

% Run optimization
[opt_params, final_rmse] = fminsearch(objectiveFun, params_initial);

% Retrieve step history
history = step_history;

%% === Figure 3: Optimized Fit ===
V_opt = model_fun(opt_params, cap_common);
figure; hold on;
plot(cap_common, voltage_exp_interp, '--', 'LineWidth', 2, 'DisplayName', 'Experimental');
plot(cap_common, V_opt, '-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Optimized Model (a=%.3f, b=%.3f, c=%.3f, d=%.3f)', opt_params));
xlabel('Capacity / mA·h'); ylabel('Voltage / V');
title(sprintf('Figure 3: Optimized Fit (RMSE = %.3f V)', final_rmse), 'FontWeight', 'bold');
legend('Location', 'best'); grid on;

%% === Figure 4: Cost Landscape With Optimization Path ===
figure;
contourf(b_vals, a_vals, RMSE_map, 30); colorbar;
xlabel('Parameter b'); ylabel('Parameter a');
title('Figure 4: Cost Landscape With Optimization Steps');
hold on;
plot(history(:,2), history(:,1), 'w.-', 'LineWidth', 1.5, 'DisplayName', 'Optimization Path');
plot(history(1,2), history(1,1), 'ro', 'MarkerSize', 8, 'DisplayName', 'Start');
plot(history(end,2), history(end,1), 'go', 'MarkerSize', 8, 'DisplayName', 'End');
legend('Location', 'northwest'); grid on; hold off;

%% === Print Summary ===
fprintf('\n=== Optimization Summary ===\n');
fprintf('Number of steps: %d\n', size(history, 1));
for i = 1:size(history, 1)
    fprintf('Step %2d: a = %.4f, b = %.4f, c = %.4f, d = %.4f, RMSE = %.6f\n', ...
        i, history(i,1), history(i,2), history(i,3), history(i,4), history(i,5));
end
fprintf('Final RMSE: %.6f\n', final_rmse);


%% === Logging Function (NOT NESTED, so we use global) ===
function rmse = storeStep(p, cap_common, voltage_exp_interp, model_fun)
    global step_history
    v_model = model_fun(p, cap_common);
    rmse = sqrt(mean((voltage_exp_interp - v_model).^2));
    step_history(end+1, :) = [p, rmse];
end