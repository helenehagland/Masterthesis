% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
output = runBatteryJson(jsonstruct);
states = output.states;

% Extract simulation data
time = cellfun(@(state) state.time / 3600, states); % Time in hours
x_elyte = output.model.grid.cells.centroids; % Electrolyte grid centroids

% Preallocate matrices for contour plots
numSteps = length(states);
c_ne = zeros(numel(states{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface), numSteps);
c_pe = zeros(numel(states{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface), numSteps);
c_elyte = zeros(numel(x_elyte), numSteps);

phi_ne = zeros(numel(states{end}.NegativeElectrode.Coating.phi), numSteps);
phi_pe = zeros(numel(states{end}.PositiveElectrode.Coating.phi), numSteps);
phi_elyte = zeros(numel(x_elyte), numSteps);

% Populate the matrices
for step = 1:numSteps
    c_ne(:, step) = states{step}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
    c_pe(:, step) = states{step}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
    c_elyte(:, step) = states{step}.Electrolyte.c;

    phi_ne(:, step) = states{step}.NegativeElectrode.Coating.phi;
    phi_pe(:, step) = states{step}.PositiveElectrode.Coating.phi;
    phi_elyte(:, step) = states{step}.Electrolyte.phi;
end

% Create the contour plots
figure; % Create a new figure
colormap(sky);

% Negative Electrode Concentration
subplot(2, 3, 1);
contourf(1:size(c_ne, 1), time, c_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Index');
ylabel('Time (h)');
title('Negative Electrode Concentration / mol·L^{-1}');

% Electrolyte Concentration
subplot(2, 3, 2);
contourf(x_elyte, time, c_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position (m)');
ylabel('Time (h)');
title('Electrolyte Concentration / mol·L^{-1}');

% Positive Electrode Concentration
subplot(2, 3, 3);
contourf(1:size(c_pe, 1), time, c_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Index');
ylabel('Time (h)');
title('Positive Electrode Concentration / mol·L^{-1}');

% Negative Electrode Potential
subplot(2, 3, 4);
contourf(1:size(phi_ne, 1), time, phi_ne', 20, 'LineColor', 'none');
colorbar;
xlabel('Index');
ylabel('Time (h)');
title('Negative Electrode Potential / V');

% Electrolyte Potential
subplot(2, 3, 5);
contourf(x_elyte, time, phi_elyte', 20, 'LineColor', 'none');
colorbar;
xlabel('Position (m)');
ylabel('Time (h)');
title('Electrolyte Potential / V');

% Positive Electrode Potential
subplot(2, 3, 6);
contourf(1:size(phi_pe, 1), time, phi_pe', 20, 'LineColor', 'none');
colorbar;
xlabel('Index');
ylabel('Time (h)');
title('Positive Electrode Potential / V');

% Add a main title
sgtitle('Contour Plots of Concentrations and Potentials Over Time');
