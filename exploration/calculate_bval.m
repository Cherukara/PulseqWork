function s_bval = calculate_bval(gr_amp, big_delta, lil_delta, epsilon)
%CALCULATE_BVAL calculates diffusion gradient b-value
%   Returns the b-value from a pair of trapezoidal diffusion sensitizing
%   gradients, with parameters "gr_amp", "Delta", "delta", and "epsilon"
%   [optional]. 
%
%   gr_amp should be supplied in mT/m, and timings should be supplied in ms

arguments 
    gr_amp (1,1) double {mustBePositive}
    big_delta (1,1) double {mustBePositive}
    lil_delta (1,1) double {mustBePositive,mustBeLessThan(lil_delta,big_delta)}
    epsilon (1,1) double {mustBeNonnegative} = 0;
end

% Proton gyromagnetic ratio, specified in s^-1 mT^-1
S_GAMMA = 2.6752218708e5;

% Calculate b-value using formula from Mattiello, 1994
s_bval = ((S_GAMMA.*gr_amp).^2) .* ( (lil_delta.^2).*(big_delta - (lil_delta/3)) ...
                                + (epsilon.^3)/30 ...
                                - (lil_delta.*epsilon.^2)/6 );

% Scale into s/mm^2
s_bval = s_bval.*1e-15;

end