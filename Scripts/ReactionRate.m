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

% Define the k0 values for negative and positive electrodes
k_neg = [4.5e-11, 5.0e-11, 5.5e-11]; % Negative electrode reaction rate constants
k_pos = [2.0e-11, 2.3e-11, 2.6e-11]; % Positive electrode reaction rate constants

% Initialize arrays for storing results
time_values = {};
j0_neg_values = {};
j0_pos_values = {};
legend_entries = {};

% Loop through k0 combinations for each electrode
figure;
hold on;

for i = 1:numel(k_neg)
    for j = 1:numel(k_pos)
        % Update the reaction rate constants in the input JSON
        jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k_neg(i);
        jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = k_pos(j);

        % Run the simulation
        output = runBatteryJson(jsonstruct);
        states = output.states;

        % Initialize temporary storage for this run
        time = [];
        j0_neg = [];
        j0_pos = [];

        % Loop through all states to calculate j0
        for k = 1:length(states)
            % Extract necessary fields
            if isfield(states{k}, 'NegativeElectrode') && ...
               isfield(states{k}.NegativeElectrode, 'Coating') && ...
               isfield(states{k}.PositiveElectrode, 'Coating') && ...
               isfield(states{k}.Electrolyte, 'c') && ...
               isfield(states{k}.ThermalModel, 'T') && ...
               isfield(states{k}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion, 'cSurface') && ...
               isfield(states{k}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion, 'cSurface')

                T = states{k}.ThermalModel.T;
                cNegElectrode = states{k}.NegativeElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
                cNegElyte = states{k}.Electrolyte.c;
                cPosElectrode = states{k}.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.cSurface;
                cPosElyte = states{k}.Electrolyte.c;

                % Ensure scalar values
                cNegElectrode = mean(cNegElectrode(:));
                cNegElyte = mean(cNegElyte(:));
                cPosElectrode = mean(cPosElectrode(:));
                cPosElyte = mean(cPosElyte(:));
                T = mean(T(:));

                % Constants
                F = 96485;
                R = 8.314;

                % Calculate reaction rate constants
                k_neg_i = k_neg(i) * exp(-5000 / (R * (1 / T - 1 / 298.15)));
                k_pos_j = k_pos(j) * exp(-5000 / (R * (1 / T - 1 / 298.15)));

                % Calculate exchange current densities
                coef_neg = cNegElyte * (35259 - cNegElectrode) * cNegElectrode; % saturation concentration for negative electrode
                coef_pos = cPosElyte * (23279 - cPosElectrode) * cPosElectrode; % saturation concentration for positive electrode
                j0_neg = [j0_neg; k_neg_i * sqrt(max(coef_neg, 0)) * F];
                j0_pos = [j0_pos; k_pos_j * sqrt(max(coef_pos, 0)) * F];

                % Time
                time = [time; states{k}.time];
            end
        end

        % Store results for plotting
        time_values{end + 1} = time;
        j0_neg_values{end + 1} = j0_neg;
        j0_pos_values{end + 1} = j0_pos;

        % Plot results
        plot(time, j0_neg, '-', 'LineWidth', 2, 'DisplayName', sprintf('Neg., k=%.1e', k_neg(i)));
        plot(time, j0_pos, '--', 'LineWidth', 2, 'DisplayName', sprintf('Pos., k=%.1e', k_pos(j)));
        legend_entries{end + 1} = sprintf('Neg., k=%.1e', k_neg(i));
        legend_entries{end + 1} = sprintf('Pos., k=%.1e', k_pos(j));
    end
end

% Customize plot
xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Exchange Current Density (j_0) [A/m²]', 'FontSize', 14, 'FontWeight', 'bold');
title('Exchange Current Density for Negative and Positive Electrodes with Varied k_0', 'FontSize', 16);
legend('Location', 'best', 'FontSize', 12);
grid on;
hold off;

% Save the plot
set(gcf, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]); % Full screen
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [16, 12]);
set(gcf, 'PaperPosition', [0, 0, 16, 12]);
exportgraphics(gcf, '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/Figurer/NyRapport/Exchange_Current_Density_Varied_k0.pdf', ...
    'ContentType', 'vector', 'Resolution', 300);