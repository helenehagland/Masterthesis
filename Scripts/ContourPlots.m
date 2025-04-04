% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'discharging';

% Extract data
states = output.states;

% Extract simulation data
time = cellfun(@(state) state.time / 3600, states); % Time in hours
numSteps = length(states);

% Define shorthand names
ne = 'NegativeElectrode';
pe = 'PositiveElectrode';
co = 'Coating';
am = 'ActiveMaterial';
sd = 'SolidDiffusion';

% Extract grid positions
x_ne = output.model.(ne).(co).grid.cells.centroids; % Negative electrode positions
x_pe = output.model.(pe).(co).grid.cells.centroids; % Positive electrode positions
x_elyte = output.model.grid.cells.centroids;        % Electrolyte positions

% Initialize matrices for contour plots
c_ne = zeros(numel(x_ne), numSteps);
c_pe = zeros(numel(x_pe), numSteps);
c_elyte = zeros(numel(x_elyte), numSteps);

phi_ne = zeros(numel(x_ne), numSteps);
phi_pe = zeros(numel(x_pe), numSteps);
phi_elyte = zeros(numel(x_elyte), numSteps);

% Populate matrices with state data
for step = 1:numSteps
    c_ne(:, step) = states{step}.(ne).(co).(am).(sd).cSurface;
    c_pe(:, step) = states{step}.(pe).(co).(am).(sd).cSurface;
    c_elyte(:, step) = states{step}.Electrolyte.c;

    phi_ne(:, step) = states{step}.(ne).(co).phi;
    phi_pe(:, step) = states{step}.(pe).(co).phi;
    phi_elyte(:, step) = states{step}.Electrolyte.phi;
end

%% === Figure 1: Contour Plots Over Time ===
figure;
colormap(sky);

subplot(2, 3, 1); contourf(x_ne, time, c_ne', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Negative Electrode Conc.');

subplot(2, 3, 2); contourf(x_elyte, time, c_elyte', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Electrolyte Conc.');

subplot(2, 3, 3); contourf(x_pe, time, c_pe', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Positive Electrode Conc.');

subplot(2, 3, 4); contourf(x_ne, time, phi_ne', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Negative Electrode Pot.');

subplot(2, 3, 5); contourf(x_elyte, time, phi_elyte', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Electrolyte Pot.');

subplot(2, 3, 6); contourf(x_pe, time, phi_pe', 20, 'LineColor', 'none'); colorbar;
xlabel('Position / m'); ylabel('Time / h'); title('Positive Electrode Pot.');

%% === Figure 2: State at Final Time Step ===
final_idx = numSteps;
figure;

subplot(2, 3, 1); plot(x_ne, c_ne(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Conc. (mol/L)'); title('Neg. Electrode Conc.');

subplot(2, 3, 2); plot(x_elyte, c_elyte(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Conc. (mol/L)'); title('Electrolyte Conc.');

subplot(2, 3, 3); plot(x_pe, c_pe(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Conc. (mol/L)'); title('Pos. Electrode Conc.');

subplot(2, 3, 4); plot(x_ne, phi_ne(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Potential (V)'); title('Neg. Electrode Pot.');

subplot(2, 3, 5); plot(x_elyte, phi_elyte(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Potential (V)'); title('Electrolyte Pot.');

subplot(2, 3, 6); plot(x_pe, phi_pe(:, final_idx), 'LineWidth', 2);
xlabel('Position / m'); ylabel('Potential (V)'); title('Pos. Electrode Pot.');

set(gcf, 'Position', [100, 100, 1200, 600]);

% % === Estimate SOC over time ===
% SOC = cellfun(@(s) s.SOC, states);
% [SOC_unique, ia, ~] = unique(SOC, 'stable');
% SOC_unique_diffsafe = SOC_unique + (0:length(SOC_unique)-1)' * 1e-6;
% time_SOC = time(ia);
% 
% % Interpolate state data
% c_ne_SOC = interp1(time, c_ne', time_SOC, 'linear')';
% c_pe_SOC = interp1(time, c_pe', time_SOC, 'linear')';
% c_elyte_SOC = interp1(time, c_elyte', time_SOC, 'linear')';
% phi_ne_SOC = interp1(time, phi_ne', time_SOC, 'linear')';
% phi_pe_SOC = interp1(time, phi_pe', time_SOC, 'linear')';
% phi_elyte_SOC = interp1(time, phi_elyte', time_SOC, 'linear')';
% 
% %% === Figure 3: SOC vs Position ===
% figure;
% colormap(sky);
% 
% subplot(2, 3, 1); contourf(x_ne, SOC_unique_diffsafe, c_ne_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Neg. Electrode Conc.');
% 
% subplot(2, 3, 2); contourf(x_elyte, SOC_unique_diffsafe, c_elyte_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Electrolyte Conc.');
% 
% subplot(2, 3, 3); contourf(x_pe, SOC_unique_diffsafe, c_pe_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Pos. Electrode Conc.');
% 
% subplot(2, 3, 4); contourf(x_ne, SOC_unique_diffsafe, phi_ne_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Neg. Electrode Pot.');
% 
% subplot(2, 3, 5); contourf(x_elyte, SOC_unique_diffsafe, phi_elyte_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Electrolyte Pot.');
% 
% subplot(2, 3, 6); contourf(x_pe, SOC_unique_diffsafe, phi_pe_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('Position / m'); ylabel('SOC'); title('Pos. Electrode Pot.');
% 
% %% === Figure 4: SOC vs Time ===
% figure;
% colormap(sky);
% 
% subplot(2, 3, 1); contourf(SOC_unique_diffsafe, time_SOC, c_ne_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Neg. Electrode Conc.');
% 
% subplot(2, 3, 2); contourf(SOC_unique_diffsafe, time_SOC, c_elyte_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Electrolyte Conc.');
% 
% subplot(2, 3, 3); contourf(SOC_unique_diffsafe, time_SOC, c_pe_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Pos. Electrode Conc.');
% 
% subplot(2, 3, 4); contourf(SOC_unique_diffsafe, time_SOC, phi_ne_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Neg. Electrode Pot.');
% 
% subplot(2, 3, 5); contourf(SOC_unique_diffsafe, time_SOC, phi_elyte_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Electrolyte Pot.');
% 
% subplot(2, 3, 6); contourf(SOC_unique_diffsafe, time_SOC, phi_pe_SOC', 20, 'LineColor', 'none'); colorbar;
% xlabel('SOC'); ylabel('Time / h'); title('Pos. Electrode Pot.');
