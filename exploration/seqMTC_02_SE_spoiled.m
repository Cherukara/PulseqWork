% Matt's modification of the FID sequence from Tutorial 1 "From FID to PRESS"
%      Adding spoiler gradients after 
%
% Modified 2026-03-05


clearvars; close all;

%% Set Up

% Define basic parameters of the system (times in seconds)
system = mr.opts('rfRingdownTime', 20e-6, 'rfDeadTime', 100e-6, ...
                 'adcDeadTime', 20e-6);

% Create a new sequence object
seq=mr.Sequence(system);      

% Define some timing parameters
Nx=128;
Nrep=1;
adcDur=6.4e-3; 
rfDur=1000e-6;
TR=13e-3;
TE=10e-3;


%% Define the Events

% Create non-selective excitation pulse
rf_ex = mr.makeBlockPulse(pi/2,'Duration',rfDur, 'system', system, 'use', 'excitation');

% Create refocusing pulse
rf_ref = mr.makeBlockPulse(pi,'Duration',rfDur, 'system',system, 'use', 'refocusing');
    
% Define ADC event
adc = mr.makeAdc(Nx,'Duration',adcDur, 'system', system );

% Calculate delays

% The first delay (between EX and REF) is TE/2 minus half the duration and
% ringdown time of the EX pulse, minus half the shape and delay of the REF pulse
delay_TE1 = (TE/2) - (rf_ex.shape_dur/2) - rf_ex.ringdownTime - rf_ref.delay - (rf_ref.shape_dur/2);

% The second delay (between REF and READ) is TE/2 minus half the duration and
% ringdown time of the REF pulse, minus half the duration of the ADC
delay_TE2 = (TE/2) - (rf_ref.shape_dur/2) - rf_ref.ringdownTime - (adcDur/2);

% Calculate TR delay
delay_TR = TR - mr.calcDuration(rf_ex) - delay_TE1 - mr.calcDuration(rf_ref);

% Assert delays must be positive
assert(delay_TR >= 0);
assert(delay_TE1 >= 0);
assert(delay_TE2 >= 0);

%% Add Event Blocks to the Sequence

% Loop over repetitions and define sequence blocks
for i=1:Nrep
    seq.addBlock(rf_ex);
    seq.addBlock(delay_TE1);
    seq.addBlock(rf_ref);
    seq.addBlock(delay_TE2-adc.delay); % Why is there a minus here?
    seq.addBlock(adc,mr.makeDelay(delay_TR));
end

%% Plot

seq.plot();

%% Check and Save

% check whether the timing of the sequence is compatible with the scanner
[ok, error_report]=seq.checkTiming;

if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

seq.setDefinition('Name', 'test_seq');
seq.write('test_seq.seq')       % Write to pulseq file
%seq.install('siemens');    % copy to scanner

%% Test Report

% optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slewrate limits  
rep = seq.testReport; 
fprintf([rep{:}]); 
