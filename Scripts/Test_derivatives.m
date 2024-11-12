%jsonstruct = parseBattmoJson('ProjectThesis/Parameter_Files/SampleInput_LNMO.json');
jsonstruct = parseBattmoJson('Examples/JsonDataFiles/sample_input.json');
jsonstruct_material.include_current_collectors = true;

jsonstruct.PositiveElectrode.Coating.ActiveMaterial.density = jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.density;
jsonstruct.Control.DRate = 10;

%% Figure 1: Parameter Sweep for Diffusion Coefficient
figure(1); % Create a new figure window
diffusion = [1e-14, 1e-16, 5e-17];  % Define three different diffusion coefficients
voltages = cell(1, numel(diffusion)); % Store voltages for each diffusion value
capacities = cell(1, numel(diffusion)); % Store capacities for each diffusion value

for i = 1:numel(diffusion)
    % Update diffusion coefficient
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = diffusion(i);

    % Run the simulation
    output(i) = runBatteryJson(jsonstruct);
    states = output(i).states;

    % Extract time, voltage, and current quantities
    time = cellfun(@(state) state.time, states);
    voltage = cellfun(@(state) state.('Control').E, states);
    current = cellfun(@(state) state.('Control').I, states);

    % Calculate capacity
    capacity = time .* current;
    
    % Store capacity and voltage values
    capacities{i} = capacity;
    voltages{i} = voltage;
    
    % Plot the discharge curve directly as before
    plot((capacity/(milli*hour)), voltage, '-', 'linewidth', 3, 'DisplayName', ['Diffusion: ', num2str(diffusion(i))])
    hold on;
end
hold off;
xlabel('Capacity  /  mA \cdot h')
ylabel('Voltage  /  V')
title('Parameter Sweep: Diffusion Coefficient')
legend show % Display legend for different diffusion coefficients


%% Figure 2: Parameter Sweep for Reaction Rate Constant (k0)
figure(2); % Create a new figure window for reaction rate constant sweep
reaction_rate_constant = [1e-9, 2.33e-11, 5e-11];  % Define three different reaction rate constants
voltages_k0 = cell(1, numel(reaction_rate_constant)); % Store voltages for each k0 value
capacities_k0 = cell(1, numel(reaction_rate_constant)); % Store capacities for each k0 value

for i = 1:numel(reaction_rate_constant)
    % Update reaction rate constant for positive electrode
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = reaction_rate_constant(i);

    % Run the simulation
    output(i) = runBatteryJson(jsonstruct);
    states = output(i).states;

    % Extract time, voltage, and current quantities
    time = cellfun(@(state) state.time, states);
    voltage = cellfun(@(state) state.('Control').E, states);
    current = cellfun(@(state) state.('Control').I, states);

    % Calculate capacity
    capacity = time .* current;
    
    % Store capacity and voltage values
    capacities_k0{i} = capacity;
    voltages_k0{i} = voltage;
    
    % Plot the discharge curve directly as before
    plot((capacity/(milli*hour)), voltage, '-', 'linewidth', 3, 'DisplayName', ['k0: ', num2str(reaction_rate_constant(i))])
    hold on;
end
hold off;
xlabel('Capacity  /  mA \cdot h')
ylabel('Voltage  /  V')
title('Parameter Sweep: Reaction Rate Constant (k0)')
legend show % Display legend for different reaction rate constants


%% Calculate and Plot Derivatives (using interpolated capacities)

% Common capacity range for derivative calculation (can be adjusted)
common_capacity = linspace(0, 3, 100); % Adjust range if needed

% Derivatives for Diffusion Coefficient
figure(3);
dVdD = zeros(numel(diffusion) - 1, length(common_capacity)); % Preallocate derivative array
for i = 1:numel(diffusion) - 1
    % Interpolate voltages for common capacity
    voltages_interp{i} = interp1(capacities{i}, voltages{i}, common_capacity);
    voltages_interp{i+1} = interp1(capacities{i+1}, voltages{i+1}, common_capacity);
    
    % Calculate voltage difference (deltaVoltage) and deltaDiffusion
    deltaV = voltages_interp{i+1} - voltages_interp{i};    % Voltage difference at corresponding points
    deltaD = diffusion(i+1) - diffusion(i);                % Diffusion coefficient difference

    % Calculate dV/dD (derivative)
    dVdD(i, :) = deltaV / deltaD;

    % Plot the derivative
    plot(common_capacity, dVdD(i, :), '-', 'linewidth', 3, 'DisplayName', ['dV/dD: ', num2str(diffusion(i))])
    hold on;
end
hold off;
xlabel('Capacity  /  mA \cdot h')
ylabel('dV/dD')
title('Derivative of Voltage wrt Diffusion Coefficient')
legend show % Display legend


% Derivatives for Reaction Rate Constant (k0)
figure(4);
dVdk0 = zeros(numel(reaction_rate_constant) - 1, length(common_capacity)); % Preallocate derivative array
for i = 1:numel(reaction_rate_constant) - 1
    % Interpolate voltages for common capacity
    voltages_interp_k0{i} = interp1(capacities_k0{i}, voltages_k0{i}, common_capacity);
    voltages_interp_k0{i+1} = interp1(capacities_k0{i+1}, voltages_k0{i+1}, common_capacity);
    
    % Calculate voltage difference (deltaVoltage) and delta_k0
    deltaV_k0 = voltages_interp_k0{i+1} - voltages_interp_k0{i};    % Voltage difference at corresponding points
    delta_k0 = reaction_rate_constant(i+1) - reaction_rate_constant(i);  % Reaction rate constant difference

    % Calculate dV/dk0 (derivative)
    dVdk0(i, :) = deltaV_k0 / delta_k0;

    % Plot the derivative
    plot(common_capacity, dVdk0(i, :), '-', 'linewidth', 3, 'DisplayName', ['dV/dk0: ', num2str(reaction_rate_constant(i))])
    hold on;
end
hold off;
xlabel('Capacity  /  mA \cdot h')
ylabel('dV/dk0')
title('Derivative of Voltage wrt Reaction Rate Constant (k0)')
legend show % Display legend
