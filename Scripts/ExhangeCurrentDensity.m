% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 0.5;
jsonstruct.Control.upperCutoffVoltage = 4;
jsonstruct.Control.initialControl = 'charging';
output = runBatteryJson(jsonstruct);
states = output.states;

% Create a vector of different diffusion coefficients
j0 = [1e-11, 2.33e-11, 5e-11];

% Instantiate an empty cell array to store the outputs of the simulations
output = cell(size(j0));

% Instantiate an empty figure
figure();

% Use a for-loop to iterate through the vector of diffusion coefficients
for i = 1:numel(j0)
    % Modify the value for the reference diffusion coefficient
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface. = j0(i);
    
    % Run the simulation and store the results in the output cell array
    output{i} = runBatteryJson(jsonstruct);
    
    % Retrieve the states from the simulation result
    states = output{i}.states;
    
    % Extract the time, voltage, and current quantities
    time = cellfun(@(state) state.time, states);
    voltage = cellfun(@(state) state.('Control').E, states);
    current = cellfun(@(state) state.('Control').I, states);
    
    % Calculate the capacity from model data
    capacity = flip(time .* -1 .* current);
    
    % Plot the discharge curve in the figure
    plot((capacity / (milli * hour)), voltage, '-', 'linewidth', 3, 'DisplayName', sprintf('k = %.0e ', j0(i)));
    hold on;
end

% Label the plot
xlabel('Capacity / mA \cdot h');
ylabel('Voltage / V');
legend('Location', 'best'); % Add legend with automatically assigned names
grid on;
hold off;
