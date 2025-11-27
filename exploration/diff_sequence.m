classdef diff_sequence
    %DIFF_SEQUENCE Diffusion MRI sequence parameters
    %   Detailed explanation goes here

properties
    % System Properties - considered to intrinsic to the scanner and
    % constraining all the rest of the optimization
    Sys_GradSlew (1,1) double {mustBePositive} = 100
    Sys_GradMaxAmp (1,1) double {mustBePositive} = 45
    Sys_TimeExcite (1,1) double {mustBePositive} = 4
    Sys_TimeRefoc (1,1) double {mustBePositive} = 4
    Sys_TimeRead (1,1) double {mustBePositive} = 4
    Sys_GAMMA (1,1) double {mustBePositive} = 2.6752218708e8;

    % Sequence Properties
    Seq_TR (1,1) double 
    Seq_TE (1,1) double 

    % Gradient Encoding Properties
    Diff_GradAmp (1,1) double
    Diff_BigDelta (1,1) double
    Diff_LilDelta (1,1) double 
    Diff_Epsilon (1,1) double {mustBeNonnegative} = 0
    Diff_bVal (1,1) double 


end % properties

methods

    % Constructor Method
    function obj = diff_sequence(TR,TE,GradAmp,BigDelta,LilDelta,Epsilon)
        %DIFF_SEQUENCE Construct a Diffusion Sequence 
        if nargin > 0
            obj.Seq_TR = TR;
            obj.Seq_TE = TE;
    
            obj.Diff_GradAmp = GradAmp;
            obj.Diff_BigDelta = BigDelta;
            obj.Diff_LilDelta = LilDelta;
            obj.Diff_Epsilon = Epsilon;
            obj.Diff_bVal = 0; % Example calculation for b-value
        end
    end

    % Calculate Ramp Time
    function obj = calculate_ramptime(obj)
        obj.Diff_Epsilon = obj.Diff_GradAmp./obj.Sys_GradSlew;
    end

    % Calculate b-value



   
end % methods
end % classdef