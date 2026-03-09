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
Nx=8192;
Nrep=1;
adcDur=12.4e-3; 
rfDur=1000e-6;
TR=80e-3;
TE=50e-3;

% Define spoiler area (in 1/m = Hz/m*s)
spA = 3000;


%% Define the Events

% Create non-selective excitation pulse
rf_ex = mr.makeBlockPulse(pi/2,'Duration',rfDur, 'system', system, 'use', 'excitation');

% Create refocusing pulse
rf_ref = mr.makeBlockPulse(pi,'Duration',rfDur, 'system',system, 'use', 'refocusing');

% Create spoiler gradient
g_sp = mr.makeTrapezoid('z','Area',spA,'system',system);

% Possibly add extra delay to the REF pulse
rf_ref.delay=max(mr.calcDuration(g_sp),rf_ref.delay);

% Calculate delays

% The first delay (between EX and REF) is TE/2 minus half the duration and
% ringdown time of the EX pulse, minus half the shape and delay of the REF pulse
delay_TE1 = (TE/2) - (rf_ex.shape_dur/2) - rf_ex.ringdownTime - rf_ref.delay - (rf_ref.shape_dur/2);

% The second delay (between REF and READ) is TE/2 minus half the duration and
% ringdown time of the REF pulse, minus half the duration of the ADC
delay_TE2 = (TE/2) - (rf_ref.shape_dur/2) - rf_ref.ringdownTime - (adcDur/2);

% Define ADC event
adc = mr.makeAdc(Nx,'Duration',adcDur, 'system', system, 'delay', delay_TE2);

% Calculate TR delay
delay_TR = TR - mr.calcDuration(rf_ex) - delay_TE1 - mr.calcDuration(rf_ref);

% Assert delays must be positive
assert(delay_TR >= 0);
assert(delay_TE1 >= 0);
assert(delay_TE2 >= 0);

% Assert delay 2 must be long enough for the spoiler gradient
assert(delay_TE2 > mr.calcDuration(g_sp));



%% Add Event Blocks to the Sequence

% Loop over repetitions and define sequence blocks
for i=1:Nrep
    seq.addBlock(rf_ex);
    seq.addBlock(delay_TE1);

    % The refocusing and spoiler are added in the same addBlock call
    seq.addBlock(rf_ref,g_sp);
    % seq.addBlock(rf_ref);
    % seq.addBlock(g_sp);

    % The ADC and spoiler are also added in the same block?
    seq.addBlock(adc,g_sp,mr.makeDelay(delay_TR));
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
