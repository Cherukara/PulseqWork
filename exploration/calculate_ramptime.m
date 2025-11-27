function epsilon = calculate_ramptime(Params_Sys, Params_Diff)
%CALCULATE_RAMPTIME calculates diffusion gradient ramp time
%   Returns the ramp time epsilon (in ms) for a trapezoidal gradient with
%   amplitude specified by Params_Diff.GradAmp (in mT/m), for a system with
%   maximum gradient slew rate specified by Params_Sys.GradSlew (in T/m/s)


% Return ramp time
epsilon = Params_Diff.GradAmp./Params_Sys.GradSlew;