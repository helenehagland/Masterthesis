jsonstruct = parseBattmoJson('ProjectThesis/Parameter_Files/SampleInput_LNMO.json');


figure()

% % Set control parameters
% jsonstruct.Control.DRate = 0.05;
% output = runBatteryJson(jsonstruct);
% states = output.states;
% 
% % Extract model data: time, voltage, and current
% time = cellfun(@(state) state.time, states);
% voltage = cellfun(@(state) state.('Control').E, states);
% current = cellfun(@(state) state.('Control').I, states);
% 
% % Calculate the capacity from model data
% capacity = time .* current;
% 
% x_ne  = output.model.NegativeElectrode.grid.cells.centroids;
% x_sep = output.model.Separator.grid.cells.centroids;
% x_pe  = output.model.PositiveElectrode.grid.cells.centroids;
% 
% plot(x_ne, zeros(size(x_ne)), 'o')
% hold on
% plot(x_sep, zeros(size(x_sep)), 'ok')
% plot(x_pe, zeros(size(x_pe)), 'or')
% xlabel('Position  /  m')


% Set control parameters
jsonstruct.Control.DRate = 0.05;
output = runBatteryJson(jsonstruct);
states = output.states;

% Define timestep for extraction, or use all time steps
num_timesteps = length(states);

disp(fields(states{1}.NegativeElectrode));
disp(fields(states{1}.PositiveElectrode));
disp(fields(states{1}.Control));
disp(fields(states{1}.Electrolyte));

% Initialize arrays for capacity and voltage for each electrode
time = zeros(num_timesteps, 1);
current = zeros(num_timesteps, 1);
phi_ne = zeros(num_timesteps, 1);  % Voltage for Negative Electrode
phi_pe = zeros(num_timesteps, 1);  % Voltage for Positive Electrode

% Loop over each timestep to extract data
for i = 1:num_timesteps
    % Time and current
    time(i) = states{i}.time;
    current(i) = states{i}.Control.I;
    
    % Voltage data (electric potential)
    phi_ne(i) = mean(states{i}.NegativeElectrode.phi); % Avg. voltage for Negative Electrode
    phi_pe(i) = mean(states{i}.PositiveElectrode.phi); % Avg. voltage for Positive Electrode
end

% Calculate capacity (cumulative integral of current over time)
capacity = cumtrapz(time, current) / (3600 * 1e-3);  % Capacity in mA·h

% Plot voltage vs. capacity for Negative Electrode (Anode)
figure;
plot(capacity, phi_ne, '-b', 'LineWidth', 2);
hold on;

% Plot voltage vs. capacity for Positive Electrode (Cathode)
plot(capacity, phi_pe, '-r', 'LineWidth', 2);

% Labels and legends
xlabel('Capacity / mA \cdot h')
ylabel('Voltage / V')
legend({'Negative Electrode (Anode)', 'Positive Electrode (Cathode)'}, 'Location', 'best')
title('Voltage vs. Capacity for Each Electrode')
grid on;
hold off;
