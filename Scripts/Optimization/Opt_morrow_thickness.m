% Load experimental data
exp_data = readtable('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx');
capacity_exp = exp_data.CapacityCby20_discharge;
voltage_exp = exp_data.VoltageCby20_discharge;
valid_idx = ~isnan(capacity_exp) & ~isnan(voltage_exp);
capacity_exp = capacity_exp(valid_idx);
voltage_exp = voltage_exp(valid_idx);
cap_common = linspace(min(capacity_exp), max(capacity_exp), 500);
voltage_exp_interp = interp1(capacity_exp, voltage_exp, cap_common, 'linear', 'extrap');

% === Init ===
x0 = [7.328e-5, 6.206e-5];  % initial thickness values

% === Optimaliseringsfunksjon ===
optfun = @(x) simulate_and_evaluate(x(1), x(2));  % ← Bare to argumenter nå!

% === Kjør fminsearch ===
[xopt, rmse_opt] = fminsearch(optfun, x0);

% === Print resultat ===
fprintf('Optimal thicknesses: neg = %.5g m, pos = %.5g m\n', xopt(1), xopt(2));
fprintf('Optimal RMSE: %.6f\n', rmse_opt);