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

Params_Seq.TR = 100;
Params_Seq.TE = 30;

Params_Diff.BigDelta = 10;
Params_Diff.LilDelta = 6;
Params_Diff.GradAmp = 30;