function [rmse, output] = simulate_and_evaluate(neg_thickness, pos_thickness)

    % === Last inn eksperimentdata ===
    exp_data = readtable('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/FullCell_Voltage_Capacity.xlsx');
    capacity_exp = exp_data.CapacityCby20_discharge;
    voltage_exp = exp_data.VoltageCby20_discharge;
    valid_idx = ~isnan(capacity_exp) & ~isnan(voltage_exp);
    capacity_exp = capacity_exp(valid_idx);
    voltage_exp = voltage_exp(valid_idx);
    cap_common = linspace(min(capacity_exp), max(capacity_exp), 500);
    voltage_exp_interp = interp1(capacity_exp, voltage_exp, cap_common, 'linear', 'extrap');

    % === Last inn JSON og konfig ===
    jsonstruct = parseBattmoJson('/Users/helenehagland/Documents/NTNU/Prosjekt og master/Prosjektoppgave/Matlab/Parameter_Files/Morrow_input.json');
    jsonstruct.Control.initialControl = 'charging';
    jsonstruct.Control.numberOfCycles = 1;
    jsonstruct.TimeStepping.numberOfTimeSteps = 400;
    jsonstruct.Control.CRate = 0.05;
    jsonstruct.Control.DRate = 0.05;
    jsonstruct.SOC = 0.1;

    jsonstruct.NegativeElectrode.Coating.thickness = neg_thickness;
    jsonstruct.PositiveElectrode.Coating.thickness = pos_thickness;

    % Juster reaksjonsrater midlertidig
    jsonstruct.NegativeElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 1e-10;
    jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.reactionRateConstant = 5e-12;

    % === Kjør simulering ===
    output = runBatteryJson(jsonstruct);

    if isempty(output.states)
        warning('Ingen states – feilet simulering');
        rmse = Inf;
        return;
    end

    % === Ekstraher data og beregn RMSE ===
    time = cellfun(@(s) s.time, output.states);
    voltage = cellfun(@(s) s.Control.E, output.states);
    current = cellfun(@(s) s.Control.I, output.states);

    % Finn discharge
    discharge_idx = current > 0;
    start_idx = find(diff([0; discharge_idx]) == 1, 1, 'first');
    end_idx = find(diff([discharge_idx; 0]) == -1, 1, 'first');

    if isempty(start_idx) || isempty(end_idx)
        warning('Fant ikke gyldig discharge');
        rmse = Inf;
        return;
    end

    idx = start_idx:end_idx;
    t = time(idx) - time(idx(1));
    i = current(idx);
    v = voltage(idx);

    cap = cumsum(i .* diff([0; t])) / 3.6;
    cap = cap - min(cap);

    % Interpoler modellen til samme punkter
    v_interp = interp1(cap, v, cap_common, 'linear', 'extrap');

    % RMSE
    rmse = sqrt(mean((v_interp - voltage_exp_interp).^2));
end