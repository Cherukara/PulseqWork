% test_diffparameters.m
%
% Main script for testing our diffusion calculation functions

clearvars;

% Define the parameter structures
Params_Sys.GradSlew = 100;
Params_Sys.GradMaxAmp = 45;
Params_Sys.TimeExcite = 4;
Params_Sys.TimeRefoc = 4;
Params_Sys.TimeRead = 4;

Params_Seq.TR = 200;
Params_Seq.TE = 100;

% Constant
S_GAMMA = 2.6752218708e8;

% Diffusion Parameters
% Diff_Grad = Params_Sys.GradMaxAmp;
Diff_Grad = 30;
Diff_Eps = Diff_Grad./Params_Sys.GradSlew;

tLilDelta = linspace(0,Params_Seq.TE./2);
tBigDelta = linspace(0,Params_Seq.TE);

% Make grid of diffusion timings
[grid_LilDelta, grid_BigDelta] = ndgrid(tLilDelta,tBigDelta);

% Calculate b-values
grid_bval = calculate_bval(Diff_Grad,grid_BigDelta,grid_LilDelta,Diff_Eps);

% Zero the ones that are invalid
grid_bval(grid_LilDelta > grid_BigDelta) = 0;

% Plot
figure('WindowStyle','docked');
surf(tBigDelta,tLilDelta,grid_bval,'EdgeColor','none');
view(2); axis square; hold on;
xlabel('\Delta (ms)')
ylabel('\delta (ms)')

% Pick out the ones closest to b=10000
grid_bval(grid_bval < 4750) = 0;
grid_bval(grid_bval > 5250) = 0;

surf(tBigDelta,tLilDelta,grid_bval);


%% Find LilDelta solution

% time difference
time_r = Diff_Eps + Params_Sys.TimeRefoc;

% b gradient term
term_b = 500./((S_GAMMA.*Diff_Grad).^2);

roots_d = roots([2/3, time_r, -Diff_Eps./6, (Diff_Eps.^2./30) - term_b]);


%% Testing how to minimize across Lil-Delta and Big-Delta

% Create Diffusion Sequence
seq1 = diff_sequence;

% Set TR and TE
seq1 = set_TR(seq1,100);
seq1 = set_TE(seq1,30);

% Desired b-value
bwant = 100;

% Set Gradient Amplitude to Max
seq1.Diff_GradAmp = seq1.Sys_GradMaxAmp;
seq1 = calculate_ramptime(seq1);

% Define range of Big Delta and Lil Delta
vec_LilDelta = getmin_lildelta(seq1):0.1:getmax_lildelta(seq1);
vec_BigDelta = getmin_bigdelta(seq1):0.1:getmax_bigdelta(seq1);

% Make a grid
[grid_LilDelta, grid_BigDelta] = ndgrid(vec_LilDelta,vec_BigDelta);

% Calculate b-values
grid_bval = calculate_bval(seq1.Diff_GradAmp,grid_BigDelta,grid_LilDelta,seq1.Diff_Epsilon);

% Zero the ones that are invalid because LilDelta is too large
grid_bval(grid_LilDelta > (grid_BigDelta - seq1.Diff_Epsilon - seq1.Sys_TimeRefoc)) = NaN;

% Zero the ones that are invalid because BigDelta is too large
grid_bval(grid_BigDelta > (seq1.Seq_TE - (seq1.Sys_TimeExcite/2) ...
                        - (seq1.Sys_TimeRead/2) - seq1.Diff_Epsilon ...
                        - grid_LilDelta)) = NaN;

% Absolute difference
grid_diff = abs(grid_bval - bwant);

% Plot
figure('WindowStyle','docked');
surf(vec_BigDelta,vec_LilDelta,grid_diff,'EdgeColor','none');
view(2); axis equal; hold on;
xlim([min(vec_BigDelta),max(vec_BigDelta)]);
ylim([min(vec_LilDelta),max(vec_LilDelta)]);
xlabel('\Delta (ms)')
ylabel('\delta (ms)')

