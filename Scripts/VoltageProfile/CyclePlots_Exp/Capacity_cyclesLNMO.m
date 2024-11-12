% Load the dataset with semicolon delimiter
data = readtable('ProjectThesis/Dataset/CapacityLNMO.csv', 'Delimiter', ';');

% Convert Capacity from string to numeric (remove commas if necessary)
data.Capacity = str2double(strrep(data.Capacity, ',', ''));

% Extract charge and discharge capacities
charge_capacity = data(data.StepIndex == 1, :);
discharge_capacity = data(data.StepIndex == 2, :);

% Extract unique cycle numbers
unique_cycles = unique(data.CycleIndex);

% Initialize arrays for charge and discharge capacities
charge_values = zeros(size(unique_cycles));
discharge_values = zeros(size(unique_cycles));

% Loop through each cycle number to assign max capacity for charge and discharge
for i = 1:length(unique_cycles)
    % Find max capacity for charge (StepIndex 1)
    charge_values(i) = max(charge_capacity.Capacity(charge_capacity.CycleIndex == unique_cycles(i)));
    
    % Find max capacity for discharge (StepIndex 2)
    discharge_values(i) = max(discharge_capacity.Capacity(discharge_capacity.CycleIndex == unique_cycles(i)));
end

% Plot the charge and discharge capacities
figure;
plot(unique_cycles, charge_values, '-o', 'DisplayName', 'Charge Capacity');
hold on;
plot(unique_cycles, discharge_values, '-x', 'DisplayName', 'Discharge Capacity');
xlabel('Cycle Number');
ylabel('Capacity');
title('Charge and Discharge Capacity vs. Cycle Number');
legend;
grid on;
