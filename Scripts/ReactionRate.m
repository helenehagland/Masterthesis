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

% Create a vector of different reaction rate constants
k = [1e-11, 2.33e-11, 5e-11];

% Instantiate empty cell arrays to store outputs and states
output = cell(size(k));
states = cell(size(k)); % Cell array to store states for each k value

% Run simulations for each reaction rate constant
for i = 1:numel(k)
    % Modify the value for the reaction rate constant
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k(i);
    
    % Run the simulation and store the results
    output{i} = runBatteryJson(jsonstruct);
    states{i} = output{i}.states;
end

% Plot voltage vs. capacity for all reaction rate constants
figure(1);
hold on;
for i = 1:numel(k)
    % Extract the time, voltage, and current quantities
    time = cellfun(@(state) state.time, states{i});
    voltage = cellfun(@(state) state.('Control').E, states{i});
    current = cellfun(@(state) state.('Control').I, states{i});
    
    % Calculate the capacity
    capacity = flip(time .* -1 .* current);
    
    % Plot voltage vs. capacity
    if i == 1
        % Clear previous labels to ensure one legend per line
        legendEntries = {};
    end
    plot((capacity / (milli * hour)), voltage, '-', 'linewidth', 2);
    legendEntries{end+1} = sprintf('k = %.0e ', k(i));
end
xlabel('Capacity / mA·h');
ylabel('Voltage / V');
title('Voltage vs. Capacity for Different Reaction Rate Constants');
legend(legendEntries, 'Location', 'best'); % Add custom legend entries
grid on;
hold off;

% Plot dashboards for each reaction rate constant
for i = 1:numel(k)
    figure(i + 1); % Create a new figure for each dashboard
    sgtitle(sprintf('Dashboard for k = %.0e', k(i))); % Overall title

    % Subplot 1: Negative Electrode Concentration
    subplot(2, 3, 1);
    try
        grid = output{i}.model.NegativeElectrode.Coating.grid;
        concentration = states{i}{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 2);
    catch
        warning('Error in Negative Electrode Concentration for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Concentration / mol L^{-1}');
    title('Negative Electrode Concentration');

    % Subplot 2: Electrolyte Concentration
    subplot(2, 3, 2);
    try
        grid = output{i}.model.Electrolyte.grid;
        concentration = states{i}{end}.Electrolyte.c ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 2);
    catch
        warning('Error in Electrolyte Concentration for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Concentration / mol L^{-1}');
    title('Electrolyte Concentration');

    % Subplot 3: Positive Electrode Concentration
    subplot(2, 3, 3);
    try
        grid = output{i}.model.PositiveElectrode.Coating.grid;
        concentration = states{i}{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 2);
    catch
        warning('Error in Positive Electrode Concentration for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Concentration / mol L^{-1}');
    title('Positive Electrode Concentration');

    % Subplot 4: Negative Electrode Potential
    subplot(2, 3, 4);
    try
        grid = output{i}.model.NegativeElectrode.Coating.grid;
        potential = states{i}{end}.NegativeElectrode.Coating.phi;
        plotCellData(grid, potential, 'linewidth', 2);
    catch
        warning('Error in Negative Electrode Potential for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Potential / V');
    title('Negative Electrode Potential');

    % Subplot 5: Electrolyte Potential
    subplot(2, 3, 5);
    try
        grid = output{i}.model.Electrolyte.grid;
        potential = states{i}{end}.Electrolyte.phi;
        plotCellData(grid, potential, 'linewidth', 2);
    catch
        warning('Error in Electrolyte Potential for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Potential / V');
    title('Electrolyte Potential');

    % Subplot 6: Positive Electrode Potential
    subplot(2, 3, 6);
    try
        grid = output{i}.model.PositiveElectrode.Coating.grid;
        potential = states{i}{end}.PositiveElectrode.Coating.phi;
        plotCellData(grid, potential, 'linewidth', 2);
    catch
        warning('Error in Positive Electrode Potential for k = %.0e', k(i));
    end
    xlabel('Position / m');
    ylabel('Potential / V');
    title('Positive Electrode Potential');
end
