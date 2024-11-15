function [OCP, dUdT] = computeOCP_LNMO_Morrow(c, T, cmax)
% Data from
%  @article{Pron_2019, title={Electrochemical Characterization and Solid Electrolyte Interface Modeling of LiNi0.5Mn1.5O4-Graphite Cells}, volume={166}, ISSN={1945-7111}, url={http://dx.doi.org/10.1149/2.0941910jes}, DOI={10.1149/2.0941910jes}, number={10}, journal={Journal of The Electrochemical Society}, publisher={The Electrochemical Society}, author={Pron, Vittorio Giai and Versaci, Daniele and Amici, Julia and Francia, Carlotta and Santarelli, Massimo and Bodoardo, Silvia}, year={2019}, pages={A2255–A2263} }

    Tref = 293.15;  % [K]


    theta = c./cmax;


    refOCP_table = [[0.000000, 4.92680];...
                    [0.010008, 4.76640];...
                    [0.020171, 4.74400];...
                    [0.030180, 4.73490];...
                    [0.040321, 4.73110];...
                    [0.050462, 4.72940];...
                    [0.060492, 4.72860];...
                    [0.070633, 4.72810];...
                    [0.080774, 4.72780];...
                    [0.090804, 4.72750];...
                    [0.100945, 4.72730];...
                    [0.111087, 4.72710];...
                    [0.121095, 4.72700];...
                    [0.131258, 4.72670];...
                    [0.141399, 4.72650];...
                    [0.151407, 4.72620];...
                    [0.161570, 4.72590];...
                    [0.171711, 4.72570];...
                    [0.181720, 4.72550];...
                    [0.191861, 4.72530];...
                    [0.202024, 4.72510];...
                    [0.212032, 4.72490];...
                    [0.222173, 4.72460];...
                    [0.232336, 4.72440];...
                    [0.242344, 4.72420];...
                    [0.252485, 4.72400];...
                    [0.262649, 4.72380];...
                    [0.272657, 4.72350];...
                    [0.282798, 4.72320];...
                    [0.292939, 4.72290];...
                    [0.302969, 4.72250];...
                    [0.313110, 4.72210];...
                    [0.323251, 4.72160];...
                    [0.333260, 4.72110];...
                    [0.343423, 4.72050];...
                    [0.353431, 4.71990];...
                    [0.363572, 4.71920];...
                    [0.373735, 4.71860];...
                    [0.383743, 4.71790];...
                    [0.393884, 4.71720];...
                    [0.404048, 4.71640];...
                    [0.414056, 4.71530];...
                    [0.424197, 4.71360];...
                    [0.434338, 4.71100];...
                    [0.444368, 4.70640];...
                    [0.454509, 4.69970];...
                    [0.464650, 4.69280];...
                    [0.474658, 4.68780];...
                    [0.484822, 4.68470];...
                    [0.494963, 4.68250];...
                    [0.504971, 4.68090];...
                    [0.515134, 4.67970];...
                    [0.525275, 4.67850];...
                    [0.535283, 4.67760];...
                    [0.545424, 4.67670];...
                    [0.555588, 4.67590];...
                    [0.565596, 4.67520];...
                    [0.575737, 4.67440];...
                    [0.585900, 4.67370];...
                    [0.595908, 4.67290];...
                    [0.606049, 4.67220];...
                    [0.616212, 4.67150];...
                    [0.626221, 4.67090];...
                    [0.636362, 4.67020];...
                    [0.646503, 4.66940];...
                    [0.656533, 4.66870];...
                    [0.666674, 4.66770];...
                    [0.676682, 4.66650];...
                    [0.686845, 4.66500];...
                    [0.696986, 4.66320];...
                    [0.706995, 4.66110];...
                    [0.717136, 4.65850];...
                    [0.727299, 4.65550];...
                    [0.737307, 4.65200];...
                    [0.747448, 4.64800];...
                    [0.757611, 4.64340];...
                    [0.767620, 4.63810];...
                    [0.777761, 4.63180];...
                    [0.787902, 4.62440];...
                    [0.797932, 4.61570];...
                    [0.808073, 4.60490];...
                    [0.818214, 4.59100];...
                    [0.828244, 4.57280];...
                    [0.838385, 4.54440];...
                    [0.848526, 4.48710];...
                    [0.858535, 4.33300];...
                    [0.868698, 4.24690];...
                    [0.878839, 4.19890];...
                    [0.888847, 4.15850];...
                    [0.899010, 4.12130];...
                    [0.909151, 4.08930];...
                    [0.919159, 4.06280];...
                    [0.929323, 4.03960];...
                    [0.939464, 4.01870];...
                    [0.949472, 3.99910];...
                    [0.959613, 3.97940];...
                    [0.969776, 3.95830];...
                    [0.979784, 3.93390];...
                    [0.989925, 3.89850];...
                    [1.000000, 3.50000]];


    refOCP = interpTable(refOCP_table(:, 1), refOCP_table(:, 2), theta);
    
    dUdT_table = [[0e-2 ,  -0.06e-3]; ...
                 [10e-2 , -0.061e-3]; ...
                 [20e-2 , -0.095e-3]; ...
                 [30e-2 , -0.123e-3]; ...
                 [40e-2 , -0.324e-3]; ...
                 [50e-2 , -0.178e-3]; ...
                 [60e-2 , -0.168e-3]; ...
                 [70e-2 , -0.191e-3]; ...
                 [80e-2 , -0.249e-3]; ...
                 [85e-2 , -2.788e-3]; ...
                 [90e-2 , -1.297e-3]; ...
                 [100e-2, -0.954e-3]];
    
    dUdT = interpTable(dUdT_table(:, 1), dUdT_table(:, 2), theta);    
    
    % Calculate the open-circuit potential of the active material
   
    OCP = refOCP + (T - Tref).*dUdT;
    
end