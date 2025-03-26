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
    c_ne(:, step) = states{step}.(ne).(co).(am).(sd).cSurface; % Negative electrode concentration
    c_pe(:, step) = states{step}.(pe).(co).(am).(sd).cSurface; % Positive electrode concentration
    c_elyte(:, step) = states{step}.Electrolyte.c; % Electrolyte concentration

    phi_ne(:, step) = states{step}.(ne).(co).phi; % Negative electrode potential
    phi_pe(:, step) = states{step}.(pe).(co).phi; % Positive electrode potential
    phi_elyte(:, step) = states{step}.Electrolyte.phi; % Electrolyte potential
end

%% **Figure 1: Contour Plots Over Time**
figure;
colormap(sky);

% Negative Electrode Concentration
subplot(2, 3, 1);
contourf(x_ne, time, c_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Negative Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');

% Electrolyte Concentration
subplot(2, 3, 2);
contourf(x_elyte, time, c_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Electrolyte Concentration', 'FontSize', 12, 'FontWeight', 'bold');

% Positive Electrode Concentration
subplot(2, 3, 3);
contourf(x_pe, time, c_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Positive Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');

% Negative Electrode Potential
subplot(2, 3, 4);
contourf(x_ne, time, phi_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Negative Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');

% Electrolyte Potential
subplot(2, 3, 5);
contourf(x_elyte, time, phi_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Electrolyte Potential', 'FontSize', 12, 'FontWeight', 'bold');

% Positive Electrode Potential
subplot(2, 3, 6);
contourf(x_pe, time, phi_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Positive Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');

%% **Figure 2: Single Time Step State Plots**
final_idx = numSteps;  % Last time step

figure;

% Negative Electrode Concentration
subplot(2, 3, 1);
plot(x_ne, c_ne(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Conc. (mol/L)', 'FontSize', 14);
title('Negative Electrode Conc.', 'FontSize', 14);

% Electrolyte Concentration
subplot(2, 3, 2);
plot(x_elyte, c_elyte(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Conc. (mol/L)', 'FontSize', 14);
title('Electrolyte Conc.', 'FontSize', 14);

% Positive Electrode Concentration
subplot(2, 3, 3);
plot(x_pe, c_pe(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Conc. (mol/L)', 'FontSize', 14);
title('Positive Electrode Conc.', 'FontSize', 14);

% Negative Electrode Potential
subplot(2, 3, 4);
plot(x_ne, phi_ne(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Potential (V)', 'FontSize', 14);
title('Negative Electrode Potential', 'FontSize', 14);

% Electrolyte Potential
subplot(2, 3, 5);
plot(x_elyte, phi_elyte(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Potential (V)', 'FontSize', 14);
title('Electrolyte Potential', 'FontSize', 14);

% Positive Electrode Potential
subplot(2, 3, 6);
plot(x_pe, phi_pe(:, final_idx), 'LineWidth', 2);
xlabel('Position / m', 'FontSize', 14);
ylabel('Potential (V)', 'FontSize', 14);
title('Positive Electrode Potential', 'FontSize', 14);


set(gcf, 'Position', [100, 100, 1200, 600]); % Adjust figure size for clarity