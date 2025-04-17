% === Coarse grid settings ===
neg_range = linspace(7.328e-5 * 0.90, 7.328e-5 * 1.10, 5);  % 90% to 110% of original neg thickness
pos_range = linspace(5.8626e-5 * 0.90, 5.8626e-5 * 1.10, 5);  % 90% to 110% of original pos thickness

rmse_grid = zeros(length(neg_range), length(pos_range));

% === Loop through combinations ===
for i = 1:length(neg_range)
    for j = 1:length(pos_range)
        neg_thick = neg_range(i);
        pos_thick = pos_range(j);
        
        fprintf('Simulating i=%d, j=%d...\n', i, j);
        
        try
            rmse = simulate_and_get_rmse(neg_thick, pos_thick, false);  % Don't show plots
        catch
            warning('Simulation failed at (%e, %e). Assigning NaN.', neg_thick, pos_thick);
            rmse = NaN;
        end

        rmse_grid(i, j) = rmse;
    end
end

% === Plot the heatmap ===
figure;
imagesc(pos_range * 1e6, neg_range * 1e6, rmse_grid);  % Convert to µm for easier reading
xlabel('Positive Thickness (µm)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Negative Thickness (µm)', 'FontSize', 12, 'FontWeight', 'bold');
title('RMSE Cost Landscape (Voltage vs Capacity)', 'FontSize', 14);
colorbar;
colormap(jet);
set(gca, 'YDir', 'normal');  % So that lower values appear at the bottom