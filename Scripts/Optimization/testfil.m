% === Last inn JSON og tving på litt tryggere oppsett ===
jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');

jsonstruct.Control.initialControl = 'charging';
jsonstruct.Control.numberOfCycles = 1;
jsonstruct.TimeStepping.numberOfTimeSteps = 400;

jsonstruct.Control.CRate = 0.05;
jsonstruct.Control.DRate = 0.05;
jsonstruct.SOC = 0.1;  % Tryggere enn 0.001!

% Overstyr tykkelser uten skalering
jsonstruct.NegativeElectrode.Coating.thickness = 7.328e-5;
jsonstruct.PositiveElectrode.Coating.thickness = 6.206e-5;

% Juster reaksjonsrater til tryggere verdier (midlertidig)
jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 5e-12;

% === Kjør simulasjon ===
output = runBatteryJson(jsonstruct);

% Sjekk volt og strøm
time = cellfun(@(s) s.time, output.states);
voltage = cellfun(@(s) s.Control.E, output.states);
current = cellfun(@(s) s.Control.I, output.states);

figure;
plot(time / 3600, voltage, 'LineWidth', 2);
xlabel('Time (h)');
ylabel('Voltage (V)');
title('Test of Stable Simulation Setup');
grid on;