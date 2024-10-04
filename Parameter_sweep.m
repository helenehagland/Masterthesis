jsonParams  = parseBattmoJson(fullfile('ParameterData', 'BatteryCellParameters', 'LithiumIonBatteryCell', 'lithium_ion_battery_lnmo_graphite.json'));
jsonGeom    = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'geometry1d.json'));
jsonControl = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'cc_discharge_control.json'));
jsonSim     = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'simulation_parameters.json'));

jsonstruct = mergeJsonStructs({jsonParams, jsonGeom, jsonControl, jsonSim});

jsonstruct.Control.useCVswitch = true;
jsonstruct.use_thermal = false;

jsonstruct.Control.upperCutoffVoltage = 4.8;
jsonstruct.Control.lowerCutoffVoltage = 4;

% jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.particleRadius = 10e-06;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.N = 20;
jsonstruct.PositiveElectrode.Coating.N = 3;

%% Figure 1: Parameter Sweep for Diffusion Coefficient
figure(1); % Create a new figure window
diffusion = [1e-11, 1e-14, 1e-15];  % Define three different diffusion coefficients

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
    
    % Plot the discharge curve in Figure 1
    plot((capacity/(milli*hour)), voltage, '-', 'linewidth', 3, 'DisplayName', ['Diffusion: ', num2str(diffusion(i))])
    hold on
end
hold off
xlabel('Capacity  /  mA \cdot h')
ylabel('Voltage  /  V')
title('Parameter Sweep: Diffusion Coefficient')
legend show % Display legend for different diffusion coefficients


jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = 1e-14;
%% Figure 2: Parameter Sweep for Reaction Rate Constant (k0)
figure(2); % Create a new figure window for reaction rate constant sweep
reaction_rate_constant = [1e-9, 2.33e-11, 5e-11];  % Define three different reaction rate constants

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
    
    % Plot the discharge curve in Figure 2
    plot((capacity/(milli*hour)), voltage, '-', 'linewidth', 3, 'DisplayName', ['k0: ', num2str(reaction_rate_constant(i))])
    hold on
end
hold off
xlabel('Capacity  /  mA \cdot h')
ylabel('Voltage  /  V')
title('Parameter Sweep: Reaction Rate Constant (k0)')
legend show % Display legend for different reaction rate constants

