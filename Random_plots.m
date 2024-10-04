% jsonstruct = parseBattmoJson('ProjectThesis/Parameter_Files/SampleInput_LNMO.json');
jsonstruct = parseBattmoJson('MATLAB/Software/BattMo/Examples/JsonDataFiles/sample_input.json');


lnmo = parseBattmoJson('MATLAB/Software/BattMo/ParameterData/MaterialProperties/LNMO/LNMO_Pron.json');
jsonstruct_lfp.PositiveElectrode.Coating.ActiveMaterial.Interface = lnmo;

% jsonstruct.PositiveElectrode.Coating.ActiveMaterial.density = jsonstruct.PositiveElectrode.Coating.ActiveMaterial.Interface.density;


figure()

%Parameter sweep, diffusion
parametersweep = false;
if parametersweep
    diffusion = [1e-12, 1e-14, 1e-16];
    
    for i = 1 : numel(diffusion)
        jsonstruct.PositiveElectrode.Coating.ActiveMaterial.SolidDiffusion.referenceDiffusionCoefficient = diffusion(i);
    
        output(i) = runBatteryJson(jsonstruct);
        states = output(i).states;
    
        % extract the time and voltage quantities
        time = cellfun(@(state) state.time, states);
        voltage = cellfun(@(state) state.('Control').E, states);
        current = cellfun(@(state) state.('Control').I, states);
    
        capacity = time .* current;
        plot((capacity/(milli*hour)), voltage, '-', 'linewidth', 3)
        hold on
    end
    hold off
    xlabel('Capacity  /  mA \cdot h')
    ylabel('Voltage  /  V')
end


%Plotting simple
simpleplot = true;
if simpleplot
    output = runBatteryJson(jsonstruct);
    states = output.states;
    
    % extract the time, voltage, and current quantities
    time = cellfun(@(state) state.time, states);
    voltage = cellfun(@(state) state.('Control').E, states);
    current = cellfun(@(state) state.('Control').I, states);
    
    % calculate the capacity
    capacity = time .* current;
    
    %plot the discharge curve in the figure
    plot((capacity/(hour*milli)), voltage, '-', 'linewidth', 3)
    hold off
    xlabel('Capacity  /  mA \cdot h')
    ylabel('Voltage  /  V')
end

sensitivityanalysis = false;

if sensitivityanalysis
    %% Setup
    mrstModule add ad-core optimization mpfa mrst-gui
    
    clear all
    close all
    
    ne      = 'NegativeElectrode';
    pe      = 'PositiveElectrode';
    elyte   = 'Electrolyte';
    thermal = 'ThermalModel';
    am      = 'ActiveMaterial';
    co      = 'Coating';
    itf     = 'Interface';
    sd      = 'SolidDiffusion';
    ctrl    = 'Control';
    sep     = 'Separator';
    
    %% Choose battery type
    
    jsonParams  = parseBattmoJson(fullfile('ParameterData', 'MaterialProperties', 'LNMO', 'LNMO_Pron.json'));
    jsonGeom    = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'geometry1d.json'));
    jsonControl = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'cc_discharge_control.json'));
    jsonSim     = parseBattmoJson(fullfile('Examples', 'JsonDataFiles', 'simulation_parameters.json'));
    
    json = mergeJsonStructs({jsonParams, jsonGeom, jsonControl, jsonSim});
    
    json.Control.useCVswitch = true;
    
    % % Test finer time discretization
    % json.TimeStepping.numberOfTimeSteps = 80;
    % json.TimeStepping.numberOfRampupSteps = 10;
    
    % Optionally validate the json struct
    validateJson = false;
    
    %% Run with initial guess
    json0 = json;
    output0 = runBatteryJson(json0, 'validateJson', validateJson);
    
    simSetup = struct('model'   , output0.model   , ...
                      'schedule', output0.schedule, ...
                      'state0'  , output0.initstate);
    
    %% Generate "experimental" data that we want to match
    jsonExp = json;
    outputExp = runBatteryJson(jsonExp, 'validateJson', validateJson);
    
    %% Plot results before optimization
    do_plot = true;
    if do_plot
        set(0, 'defaultlinelinewidth', 2)
    
        getTime = @(states) cellfun(@(state) state.time, states);
        getE = @(states) cellfun(@(state) state.Control.E, states);
    
        t0 = getTime(output0.states);
        E0 = getE(output0.states);
        tExp = getTime(outputExp.states);
        EExp = getE(outputExp.states);
    
        h = figure; hold on; grid on; axis tight
        plot(t0/hour, E0, 'displayname', 'E_{0}')           % Initial guess
        plot(tExp/hour, EExp, '--', 'displayname', 'E_{exp}') % Experimental data
        legend;
    end
    
    %% Summarize parameters (optional)
    fprintf('Initial guess parameters:\n');
    pOrig = {};  % Assuming you want to print some initial guess parameters (you can define them based on your needs)
    fprintf('%g\n', pOrig{:});
end