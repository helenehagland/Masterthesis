% Initial guess
x0 = [7.328e-5 * 0.94, 5.8626e-5];  % [neg_thickness, pos_thickness]
original = [7.328e-5, 5.8626e-5];

% Define bounds (±10%)
lb = original * 0.90;  % Lower bounds
ub = original * 1.10;  % Upper bounds

% Define objective function
objfun = @(x) safe_rmse_eval(x(1), x(2));

% Optimization options
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'MaxIterations', 10, ...
    'FunctionTolerance', 1e-4);

% Run fmincon with bounds
[xopt, rmse_opt] = fmincon(objfun, x0, [], [], [], [], lb, ub, [], options);

% Save result
writematrix([xopt, rmse_opt], 'optimized_thicknesses.csv');

% Show result and plot
fprintf("\n✅ Final optimized thicknesses:\n");
fprintf("  Negative: %.6e m\n", xopt(1));
fprintf("  Positive: %.6e m\n", xopt(2));
fprintf("  RMSE: %.5f V\n", rmse_opt);

% Plot final result
simulate_and_get_rmse(xopt(1), xopt(2), true);