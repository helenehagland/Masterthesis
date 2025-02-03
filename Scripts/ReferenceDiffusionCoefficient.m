% Load input configuration
jsonstruct = parseBattmoJson('Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

% Set control parameters
cccv_control_protocol = parseBattmoJson('cccv_control.json');
jsonstruct = mergeJsonStructs({cccv_control_protocol, jsonstruct});
jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.Control.lowerCutoffVoltage = 1;
jsonstruct.Control.upperCutoffVoltage = 3.5;
jsonstruct.Control.initialControl = 'charging';

% Create a vector of different diffusion coefficients
D0 = [1e-15, 1e-14, 1e-13];

% Instantiate empty cell arrays to store outputs and states
output = cell(size(D0));
states = cell(size(D0)); % Cell array to store states for each D0 value

% Run simulations for each diffusion coefficient
for i = 1:numel(D0)
    % Modify the value for the reference diffusion coefficient
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = D0(i);
    
    % Run the simulation and store the results
    output{i} = runBatteryJson(jsonstruct);
    states{i} = output{i}.states;
end

% Plot voltage vs. capacity for all diffusion coefficients
figure(1);
hold on;
legendEntries = {}; % Initialize legend entries
for i = 1:numel(D0)
    % Extract the time, voltage, and current quantities
    time = cellfun(@(state) state.time, states{i});
    voltage = cellfun(@(state) state.('Control').E, states{i});
    current = cellfun(@(state) state.('Control').I, states{i});
    
    % Calculate the capacity
    capacity = flip(time .* -1 .* current);
    
    % Plot voltage vs. capacity
    plot((capacity / (3600 * 1e-3)), voltage, '-', 'linewidth', 3);
    legendEntries{end+1} = sprintf('D0 = %.0e m^2/s', D0(i));
end
xlabel('Capacity / mA \cdot h', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage / V', 'FontSize', 18, 'FontWeight', 'bold');
title('Voltage vs. Capacity for Different Diffusion Coefficients', 'FontSize', 22, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'best', 'FontSize', 14); % Add custom legend entries
grid on;
ax = gca; % Get current axis
ax.FontSize = 14;
ax.FontWeight = 'bold';
hold off;

% Save Figure 1
set(gcf, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [16, 12]);
set(gcf, 'PaperPosition', [0, 0, 16, 12]);
exportgraphics(gcf, '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/Diffusion_Discharge.pdf', ...
    'ContentType', 'vector', 'Resolution', 300);

% Plot dashboards for each diffusion coefficient and save them
for i = 1:numel(D0)
    figure(i + 1); % Create a new figure for each dashboard
    sgtitle(sprintf('State plots for D0 = %.0e m^2/s', D0(i)), 'FontSize', 20, 'FontWeight', 'bold'); % Overall title

    % Subplot 1: Negative Electrode Concentration
    subplot(2, 3, 1);
    try
        grid = output{i}.model.NegativeElectrode.Coating.grid;
        concentration = states{i}{end}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 3);
    catch
        warning('Error in Negative Electrode Concentration for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Negative Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';


    % Subplot 2: Electrolyte Concentration
    subplot(2, 3, 2);
    try
        grid = output{i}.model.Electrolyte.grid;
        concentration = states{i}{end}.Electrolyte.c ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 3);
    catch
        warning('Error in Electrolyte Concentration for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Electrolyte Concentration', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Subplot 3: Positive Electrode Concentration
    subplot(2, 3, 3);
    try
        grid = output{i}.model.PositiveElectrode.Coating.grid;
        concentration = states{i}{end}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface ./ 1000;
        plotCellData(grid, concentration, 'linewidth', 3);
    catch
        warning('Error in Positive Electrode Concentration for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Positive Electrode Concentration', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Subplot 4: Negative Electrode Potential
    subplot(2, 3, 4);
    try
        grid = output{i}.model.NegativeElectrode.Coating.grid;
        potential = states{i}{end}.NegativeElectrode.Coating.phi;
        plotCellData(grid, potential, 'linewidth', 3);
    catch
        warning('Error in Negative Electrode Potential for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Negative Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Subplot 5: Electrolyte Potential
    subplot(2, 3, 5);
    try
        grid = output{i}.model.Electrolyte.grid;
        potential = states{i}{end}.Electrolyte.phi;
        plotCellData(grid, potential, 'linewidth', 3);
    catch
        warning('Error in Electrolyte Potential for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Electrolyte Potential', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Subplot 6: Positive Electrode Potential
    subplot(2, 3, 6);
    try
        grid = output{i}.model.PositiveElectrode.Coating.grid;
        potential = states{i}{end}.PositiveElectrode.Coating.phi;
        plotCellData(grid, potential, 'linewidth', 3);
    catch
        warning('Error in Positive Electrode Potential for D0 = %.0e', D0(i));
    end
    xlabel('Position / m', 'FontSize', 18, 'FontWeight', 'bold');
    title('Positive Electrode Potential', 'FontSize', 12, 'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Save each dashboard as a separate PDF
    set(gcf, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperSize', [16, 12]);
    set(gcf, 'PaperPosition', [0, 0, 16, 12]);
    exportgraphics(gcf, sprintf('/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/Diffusion_Dashboard_D0_%.0e.pdf', D0(i)), ...
        'ContentType', 'vector', 'Resolution', 300);

    % Close the figure to free memory
    close(gcf);
end
