classdef diff_sequence
    %DIFF_SEQUENCE Diffusion MRI sequence parameters
    %   Detailed explanation goes here

properties (Constant)

    % Constants
    C_GAMMA = 2.6752218708e8;

end % properties (Constant)

properties (SetAccess = protected)

    % Sequence Properties
    Seq_TR (1,1) double 
    Seq_TE (1,1) double 

end % properties (SetAccess = protected)

properties
    % System Properties - considered to intrinsic to the scanner and
    % constraining all the rest of the optimization
    Sys_GradSlew (1,1) double {mustBePositive} = 100
    Sys_GradMaxAmp (1,1) double {mustBePositive} = 45
    Sys_TimeExcite (1,1) double {mustBePositive} = 4
    Sys_TimeRefoc (1,1) double {mustBePositive} = 4
    Sys_TimeRead (1,1) double {mustBePositive} = 4

    % Gradient Encoding Properties
    Diff_GradAmp (1,1) double
    Diff_BigDelta (1,1) double
    Diff_LilDelta (1,1) double 
    Diff_Epsilon (1,1) double {mustBeNonnegative} = 0
    Diff_bVal (1,1) double 


end % properties

methods

    % --------------------------------------------------------------------------
    % 'Constructor' Method
    % --------------------------------------------------------------------------
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
        else
            obj.Seq_TE = getmin_TE(obj);
            obj.Seq_TR = getmin_TR(obj);
        end
    end

    % --------------------------------------------------------------------------
    % 'Display' Method
    % --------------------------------------------------------------------------
    function show(obj)
        fprintf('Diffusion Sequence with properties:\n\n');
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n','TR',obj.Seq_TR,obj.getmin_TR,Inf);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n','TE',obj.Seq_TE,obj.getmin_TE,obj.getmax_TE);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n',sprintf('\x394'),obj.Diff_BigDelta,0,0);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n',sprintf('\x3b4'),obj.Diff_LilDelta,0,0);
        fprintf('\t%-7s = %-10.2f [ %d, %.2f ]\n','G_diff',obj.Diff_GradAmp,0,obj.Sys_GradMaxAmp);
        fprintf('\t%-7s = %.2f\n','b-value',obj.Diff_bVal);
        fprintf('\n');
    end

    % --------------------------------------------------------------------------
    % Get Minimum TR
    % --------------------------------------------------------------------------
    function TRmin = getmin_TR(obj)
        TRmin = max(obj.Seq_TE,obj.getmin_TE) + (obj.Sys_TimeExcite/2) + (obj.Sys_TimeRead/2);
    end

    % --------------------------------------------------------------------------
    % Get Minimum TE
    % --------------------------------------------------------------------------
    function TEmin = getmin_TE(obj)
        TEmin = (obj.Sys_TimeExcite/2) ... 
              + (obj.Sys_TimeRefoc) ...
              + (obj.Sys_TimeRead/2) ...
              + (obj.Diff_BigDelta + obj.Diff_LilDelta);
    end

    % --------------------------------------------------------------------------
    % Get Maximum TE
    % --------------------------------------------------------------------------
    function TEmax = getmax_TE(obj)
        TEmax = obj.Seq_TR - (obj.Sys_TimeExcite/2) - (obj.Sys_TimeRead/2);
    end

    % --------------------------------------------------------------------------
    % Set TR
    % --------------------------------------------------------------------------
    function obj = set_TR(obj,TR)
        if (TR >= obj.getmin_TR)
            obj.Seq_TR = TR;
        else
            error("Specified TR of %.3f ms is too short. Minimum TR is %.3f ms.\n",...
                  TR,obj.getmin_TR);
        end
    end

    % --------------------------------------------------------------------------
    % Set TE
    % --------------------------------------------------------------------------
    function obj = set_TE(obj,TE)
        if (TE <= obj.getmin_TE)
            error("Specified TE of %.3f ms is too short. Minimum TE is %.3f ms.\n",...
                  TE,obj.getmin_TE);
        elseif (TE >= obj.getmax_TE)
            error("Specified TE of %.3f ms is too long. Maximum TE is %.3f ms.\n",...
                  TE,obj.getmax_TE);
        else
            obj.Seq_TE = TE;
        end
    end


    % --------------------------------------------------------------------------
    % Calculate Ramp Time
    % --------------------------------------------------------------------------
    function obj = calculate_ramptime(obj)
        obj.Diff_Epsilon = obj.Diff_GradAmp./obj.Sys_GradSlew;
    end

    % --------------------------------------------------------------------------
    % Calculate b-value
    % --------------------------------------------------------------------------
    function bval = get_bval(obj)
        bval = (1e-21)*(obj.C_GAMMA.*obj.Diff_GradAmp).^2 ...
             * ( (obj.Diff_LilDelta.^2).*(obj.Diff_BigDelta - (obj.Diff_LilDelta/3)) ...
                                + (obj.Diff_Epsilon.^3)/30 ...
                                - (obj.Diff_LilDelta.*obj.Diff_Epsilon.^2)/6 );
    end

    % --------------------------------------------------------------------------
    % Assign b-value
    % --------------------------------------------------------------------------
    function obj = calculate_bval(obj)
        obj.Diff_bVal = get_bval(obj);
    end

    % --------------------------------------------------------------------------
    % Manually Push Minimum Timings
    % --------------------------------------------------------------------------
    function obj = push_timings(obj)
        obj.Seq_TE = getmin_TE(obj);
        obj.Seq_TR = getmin_TR(obj);
    end

   
end % methods
end % classdef