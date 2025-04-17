neg_thick = 7.328e-05;        % or use value from optimizer
pos_thick = 6.206e-05;              % known good value


rmse = simulate_and_get_rmse(neg_thick, pos_thick);
fprintf('Total RMSE: %.5f V\n', rmse);