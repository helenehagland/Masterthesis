% Preallocate matrices for concentrations and potentials
num_timesteps = numel(output.states); % Number of timesteps
num_positions_ne = numel(output.states{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface);
num_positions_pe = numel(output.states{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface);
num_positions_electrolyte = numel(output.states{end}.Electrolyte.c);

% Extract electrolyte grid centroids
x_electrolyte = output.model.grid.cells.centroids; % Actual positions for the electrolyte

% Preallocate matrices
electrolyte_concentration = zeros(num_positions_electrolyte, num_timesteps);
anode_concentration = zeros(num_positions_ne, num_timesteps);
cathode_concentration = zeros(num_positions_pe, num_timesteps);
electrolyte_potential = zeros(num_positions_electrolyte, num_timesteps);
anode_potential = zeros(num_positions_ne, num_timesteps);
cathode_potential = zeros(num_positions_pe, num_timesteps);

% Time vector
time_vector = zeros(1, num_timesteps); % To store time values

% Fill the data matrices
for i = 1:num_timesteps
    electrolyte_concentration(:, i) = output.states{i}.Electrolyte.c;
    anode_concentration(:, i) = output.states{i}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
    cathode_concentration(:, i) = output.states{i}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
    
    electrolyte_potential(:, i) = output.states{i}.Electrolyte.phi;
    anode_potential(:, i) = output.states{i}.NegativeElectrode.Coating.phi;
    cathode_potential(:, i) = output.states{i}.PositiveElectrode.Coating.phi;
    
    time_vector(i) = output.states{i}.time / 3600; % Convert time to hours
end

% Use index as the position for the anode and cathode since their grid points are not provided
index_ne = 1:num_positions_ne;
index_pe = 1:num_positions_pe;

% Plot contour plots
figure;
colormap(sky);

% 1. Anode Concentration
subplot(2, 3, 1);
contourf(index_ne, time_vector, anode_concentration', 20, 'LineColor', [0.5 0.5 0.5]);
colorbar;
xlabel('Index');
ylabel('Time / h');
title('Anode Concentration / mol · L^{-1}');

% 2. Electrolyte Concentration
subplot(2, 3, 2);
contourf(x_electrolyte * 1e6, time_vector, electrolyte_concentration', 20, 'LineColor', [0.5 0.5 0.5]);
colorbar;
xlabel('Position / µm');
ylabel('Time / h');
title('Electrolyte Concentration / mol · L^{-1}');

% 3. Cathode Concentration
subplot(2, 3, 3);
contourf(index_pe, time_vector, cathode_concentration', 20, 'LineColor', [0.5 0.5 0.5]);
colorbar;
xlabel('Index');
ylabel('Time / h');
title('Cathode Concentration / mol · L^{-1}');

% 4. Anode Potential
subplot(2, 3, 4);
contourf(index_ne, time_vector, anode_potential', 20, 'LineColor', [0.5 0.5 0.5]);
colorbar;
xlabel('Index');
ylabel('Time / h');
title('Anode Potential / V');

% 5. Electrolyte Potential
subplot(2, 3, 5);
contourf(x_electrolyte * 1e6, time_vector, electrolyte_potential', 20, 'LineColor', [0.5 0.5 0.5]); 
colorbar;
xlabel('Position / µm');
ylabel('Time / h');
title('Electrolyte Potential / V');

% 6. Cathode Potential
subplot(2, 3, 6);
contourf(index_pe, time_vector, cathode_potential', 20, 'LineColor', [0.5 0.5 0.5]);
colorbar;
xlabel('Index');
ylabel('Time / h');
title('Cathode Potential / V');

% Adjust layout
sgtitle('Concentration and Potential Contour Plots');
