% Load data from the Excel file, skipping the headers in the first row
file_name = '/Users/helenehagland/Documents/NTNU/Prosjektoppgave/ProjectThesis/Dataset/Nye_dataset/OCP_LNMO_RCHL374.xlsx';  % Replace with your actual file name
data = readtable(file_name, 'ReadVariableNames', true);

% Extract charge and discharge columns
charge_values = data{:, 1};  % First column is charge values
discharge_values = data{:, 2};  % Second column is discharge values

% Define the target length for resampling
target_length = 100;

% Resample the charge values to 100 points
charge_resampled = resample(charge_values, target_length, length(charge_values));

% Resample the discharge values to 100 points
discharge_resampled = resample(discharge_values, target_length, length(discharge_values));

% Calculate the average of the resampled charge and discharge values
average_values = (charge_resampled + discharge_resampled) / 2;

% Create a table with the resampled data and appropriate headers
resampled_data = table(charge_resampled, discharge_resampled, average_values, ...
                       'VariableNames', {'Charge_Resampled', 'Discharge_Resampled', 'Average'});

% Write the resampled data to the same Excel file, starting from column C with headers
writetable(resampled_data, file_name, 'Sheet', 1, 'Range', 'C1');
