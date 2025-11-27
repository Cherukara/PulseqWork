function s_bval = calculate_bval(Params_Diff)
%CALCULATE_BVAL calculates diffusion gradient b-value
%   Returns the b-value from a pair of trapezoidal diffusion sensitizing
%   gradients, with parameters specified in the Params_Diff struct. This must
%   contain .BigDelta (in ms), .LilDelta (in ms), and .GradAmp (in mT/m).
%   Optionally, you can also supply .Epsilon (in ms)

if ~isfield(Params_Diff,'Epsilon')
    Params_Diff.Epsilon = 0;
end

big_delta = Params_Diff.BigDelta;% * 1e-3; % Convert ms to s
lil_delta = Params_Diff.LilDelta;% * 1e-3; % Convert ms to s
epsilon = Params_Diff.Epsilon ;%* 1e-3; % Convert ms to s
gr_amp = Params_Diff.GradAmp; % Gradient amplitude in mT/m

% Proton gyromagnetic ratio, specified in s^-1 mT^-1
S_GAMMA = 2.6752218708e8;

% Calculate b-value using formula from Mattiello, 1994 (will be in s/m^2)
s_bval = ((S_GAMMA.*gr_amp).^2) .* ( (lil_delta.^2).*(big_delta - (lil_delta/3)) ...
                                + (epsilon.^3)/30 ...
                                - (lil_delta.*epsilon.^2)/6 );

% Scale into s/mm^2
s_bval = s_bval.*1e-21;

end