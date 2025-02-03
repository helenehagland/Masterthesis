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
output = runBatteryJson(jsonstruct);
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

% Create contour plots
figure; 
colormap(sky);

% Negative Electrode Concentration
subplot(2, 3, 1);
contourf(x_ne, time, c_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Negative Electrode Concentration / mol·L^{-1}', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';

% Electrolyte Concentration
subplot(2, 3, 2);
contourf(x_elyte, time, c_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Electrolyte Concentration / mol·L^{-1}', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';

% Positive Electrode Concentration
subplot(2, 3, 3);
contourf(x_pe, time, c_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Positive Electrode Concentration / mol·L^{-1}', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';

% Negative Electrode Potential
subplot(2, 3, 4);
contourf(x_ne, time, phi_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Negative Electrode Potential / V', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';

% Electrolyte Potential
subplot(2, 3, 5);
contourf(x_elyte, time, phi_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Electrolyte Potential / V', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';

% Positive Electrode Potential
subplot(2, 3, 6);
contourf(x_pe, time, phi_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Time / h', 'FontSize', 18, 'FontWeight', 'bold');
title('Positive Electrode Potential / V', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';


% Set figure size for the entire figure
figureHandle = gcf; % Get current figure handle
set(figureHandle, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen
set(figureHandle, 'PaperUnits', 'inches');
set(figureHandle, 'PaperSize', [16, 12]); % Larger size for better clarity
set(figureHandle, 'PaperPosition', [0, 0, 16, 12]); % Fill the page

% Export the entire figure
exportgraphics(figureHandle, '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/ContourPlots.pdf', ...
    'ContentType', 'vector', 'Resolution', 300);
