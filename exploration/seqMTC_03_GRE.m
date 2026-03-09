% Matt's exploration of Pulseq sequences
%       Based on Tutorial 02 "Basic GRE"
%
% Modified 2026-03-05

clearvars; close all;

%% Set Up

% Define basic parameters of the system (times in seconds)
sys = mr.opts('MaxGrad',12,'GradUnit','mT/m',...
              'MaxSlew',100,'SlewUnit','T/m/s',...
              'rfRingdownTime', 20e-6, 'rfDeadtime', 100e-6);

% Create a new sequence object
seq=mr.Sequence(sys);

% Timing parameters
rfDur=4e-3;
adcDur = 6.4e-3;

% FOV and resolution
fov = 256e-3;
sliceThickness = 5e-3;
Nx=256;
Ny=8;

% Sequence parameters
TE = 8e-3;
TR = 22e-3;

alpha = 30;

% Derived parameters
deltak = 1/fov;
phaseAreas = ((0:Ny-1)-Ny/2)*deltak;


%% Define the Events

% Create slice selective alpha-pulse
[rf, gz_ss, gz_reph] = mr.makeSincPulse(alpha*pi/180, ...
                                        'Duration', rfDur,...
                                        'SliceThickness', sliceThickness,...
                                        'apodization', 0.5,...
                                        'timeBwProduct', 4,...
                                        'system', sys, ...
                                        'use', 'excitation');

% Define frequency encoding gradient
gx_read = mr.makeTrapezoid('x','FlatArea',Nx*deltak,...
                               'FlatTime', adcDur);

% Define frequency-encoding prewinder gradient
gx_pre = mr.makeTrapezoid('x','Area', -gx_read.area/2, ...
                              'Duration', 2e-3);
    
% Define ADC event
adc = mr.makeAdc(Nx,'Duration',gx_read.flatTime, ...
                    'Delay', gx_read.riseTime, ...
                    'system', sys );

% Calculate delays

% The TE delay is TE minus half the duration of the slice selection gradient,
% minus the duration of the read prewinder, minus half the duration of the
% readout gradient
delay_TE = TE - (mr.calcDuration(gz_ss)/2) ...
              - mr.calcDuration(gx_pre) ...
              - (mr.calcDuration(gx_read)/2);

% The TR delay is TR minus the full duration of the slice selection gradient
% (i.e. half of one TR plus half of the next), minus the duration of the read
% prewinder, minus the duration of the full read gradient, minus TE delay
delay_TR = TR - mr.calcDuration(gz_ss) ...
              - mr.calcDuration(gx_pre) ...
              - mr.calcDuration(gx_read) ...
              - delay_TE;

% Round the delay times to be multiples of the gradient raster time
delay_TE = round(delay_TE/seq.gradRasterTime)*seq.gradRasterTime;
delay_TR = round(delay_TR/seq.gradRasterTime)*seq.gradRasterTime;

% Assert delays must be positive
assert(delay_TE >= 0);
assert(delay_TR >= 0);


%% Add Event Blocks to the Sequence

% Loop over phase encodes
for ii = 1:Ny

    % Define phase encoding gradient
    gy_phase = mr.makeTrapezoid('y', 'Area', phaseAreas(ii), ...
                                'Duration', 2e-3);

    % Add event blocks
    seq.addBlock(rf, gz_ss);
    seq.addBlock(gx_pre, gy_phase, gz_reph);
    seq.addBlock(mr.makeDelay(delay_TE));
    seq.addBlock(gx_read, adc);
    seq.addBlock(mr.makeDelay(delay_TR));
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

seq.setDefinition('Name', 'test_GRE');
seq.write('test_GRE.seq')       % Write to pulseq file
%seq.install('siemens');    % copy to scanner

%% Test Report

% optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slewrate limits  
rep = seq.testReport; 
fprintf([rep{:}]); 
