% Load the dataset, preserving original column names and handling semicolons
data = readtable('ProjectThesis/Dataset/HalfCellLNMO.csv', 'Delimiter', ';');

% Convert necessary columns from strings to numeric values (remove commas if needed)
data.Voltage_V_ = str2double(strrep(data.Voltage_V_, ',', '.'));
data.Capacity_mAh_ = str2double(strrep(data.Capacity_mAh_, ',', '.'));

% Extract unique cycle numbers
unique_cycles = unique(data.CycleIndex);

% Initialize a figure for plotting
figure;
hold on;

% Loop through each cycle and plot Voltage vs. Capacity
for i = 1:length(unique_cycles)
    cycle_data = data(data.CycleIndex == unique_cycles(i), :);
    plot(cycle_data.Capacity_mAh_, cycle_data.Voltage_V_, 'DisplayName', ['Cycle ', num2str(unique_cycles(i))]);
end

% Customize the plot
xlabel('Capacity (mAh)');
ylabel('Voltage (V)');
title('Voltage vs. Capacity for All Cycles');
legend show;
grid on;
hold off;