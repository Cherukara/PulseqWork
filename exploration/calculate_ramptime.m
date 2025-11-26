function epsilon = calculate_ramptime(gr_amp, gr_slew)
%CALCULATE_RAMPTIME calculates diffusion gradient ramp time
%   Returns the ramp time epsilon for a trapezoidal gradient of amplitude
%   gr_amp, with a specified gradient slew rate gr_slew
%
%   gr_amp should be supplied in mT/m, gr_slew should be supplied in T/m/s

arguments
    gr_amp (1,1) double {mustBePositive}
    gr_slew (1,1) double {mustBePositive}
end

% Return ramp time
epsilon = (1e-3).*gr_amp./gr_slew;