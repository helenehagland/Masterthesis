function cost = safe_rmse_eval(neg_thick, pos_thick)
    try
        cost = simulate_and_get_rmse(neg_thick, pos_thick, false);  % Run without plot
        if ~isfinite(cost)
            warning("⚠️ Non-finite RMSE at neg=%.2e, pos=%.2e", neg_thick, pos_thick);
            cost = 1e3;
        end
    catch ME
        warning("❌ Simulation crashed at neg=%.2e, pos=%.2e", neg_thick, pos_thick);
        disp(getReport(ME, 'basic'));
        cost = 1e3;  % Large penalty if it fails
    end
end