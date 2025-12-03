classdef diff_sequence
    %DIFF_SEQUENCE Diffusion MRI sequence parameters
    %   Detailed explanation goes here

properties (Constant)

    % Constants
    C_GAMMA = 2.6752218708e8;

    % System Properties - considered to intrinsic to the scanner and
    % constraining all the rest of the optimization
    Sys_GradSlew (1,1) double {mustBePositive} = 100
    Sys_GradMaxAmp (1,1) double {mustBePositive} = 45
    Sys_TimeExcite (1,1) double {mustBePositive} = 4
    Sys_TimeRefoc (1,1) double {mustBePositive} = 4
    Sys_TimeRead (1,1) double {mustBePositive} = 4

end % properties (Constant)

properties (SetAccess = protected)

    % Sequence Properties
    Seq_TR (1,1) double 
    Seq_TE (1,1) double 

    % Gradient Encoding Properties
    Diff_Epsilon (1,1) double {mustBeNonnegative} = 0
    Diff_bVal (1,1) double

end % properties (SetAccess = protected)

properties

    % Gradient Encoding Properties
    Diff_GradAmp (1,1) double
    Diff_BigDelta (1,1) double
    Diff_LilDelta (1,1) double 

end % properties

methods

    % --------------------------------------------------------------------------
    % 'Constructor' Method
    % --------------------------------------------------------------------------
    function obj = diff_sequence(GradAmp,BigDelta,LilDelta,TR,TE)
        %DIFF_SEQUENCE Construct a Diffusion Sequence 
        if nargin > 0
            obj.Seq_TR = TR;
            obj.Seq_TE = TE;
    
            obj.Diff_GradAmp = GradAmp;
            obj.Diff_BigDelta = BigDelta;
            obj.Diff_LilDelta = LilDelta;
        else
            % If these are not specified, calculate them based on others
            obj.Seq_TE = getmin_TE(obj);
            obj.Seq_TR = getmin_TR(obj);
        end

        % Pre-calculate Epsilon
        obj = calculate_ramptime(obj);

        % Pre-calculate b-value
        obj = calculate_bval(obj);

 
    end

    % --------------------------------------------------------------------------
    % 'Display' Method
    % --------------------------------------------------------------------------
    function show(obj)
        fprintf('Diffusion Sequence with properties:\n\n');
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n','TR',obj.Seq_TR,obj.getmin_TR,Inf);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n','TE',obj.Seq_TE,obj.getmin_TE,obj.getmax_TE);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n',sprintf('\x394'),obj.Diff_BigDelta,obj.getmin_bigdelta,obj.getmax_bigdelta);
        fprintf('\t%-7s = %-10.3f [ %.2f, %.2f ] ms\n',sprintf('\x3b4'),obj.Diff_LilDelta,obj.getmin_lildelta,obj.getmax_lildelta);
        fprintf('\t%-7s = %-10.2f [ %d, %.2f ]\n','G_diff',obj.Diff_GradAmp,0,obj.Sys_GradMaxAmp);
        fprintf('\t%-7s = %-10.2f [ %d, %.2f ]\n','b-value',obj.Diff_bVal,0,obj.getmax_bval);
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
    % Get Maximum Ramp Time
    % --------------------------------------------------------------------------
    function Emax = getmax_ramp(obj)
        Emax = obj.Sys_GradMaxAmp/obj.Sys_GradSlew;
    end

    % --------------------------------------------------------------------------
    % Get Minimum Little delta
    % --------------------------------------------------------------------------
    function LilDelta = getmin_lildelta(obj)
        % The minimum duration for little delta is just ramp up time (since ramp
        % down time doesn't count as little delta time)
        LilDelta = obj.Diff_Epsilon;
    end

    % --------------------------------------------------------------------------
    % Get Maximum Little delta
    % --------------------------------------------------------------------------
    function LilDelta = getmax_lildelta(obj)
        % The maximum duration for little delta is filling the entire interval
        % between the end of the refocusing pulse and the start of the readout,
        % plus time for ramping down
        LilDelta = (obj.Seq_TE/2) ...
                 - (obj.Sys_TimeRefoc/2) ...
                 - (max(obj.Sys_TimeRead,obj.Sys_TimeExcite)/2) ...
                 - obj.Diff_Epsilon;
    end

    % --------------------------------------------------------------------------
    % Get Minimum Big Delta
    % --------------------------------------------------------------------------
    function BigDelta = getmin_bigdelta(obj)
        % The minimum duration for big Delta is one unit of little delta, plus a
        % ramp down, plus the refocusing pulse
        BigDelta = obj.Diff_LilDelta + getmax_ramp(obj) + obj.Sys_TimeRefoc;
    end

    % --------------------------------------------------------------------------
    % Get Maximum Big Delta
    % --------------------------------------------------------------------------
    function BigDelta = getmax_bigdelta(obj)
        % The maximum duration for big Delta is TE, minus half of the Excitation
        % and Readout events, minus one little delta and one ramp down
        BigDelta = obj.Seq_TE ...
                 - (obj.Sys_TimeExcite/2) ...
                 - (obj.Sys_TimeRead/2) ...
                 - obj.Diff_LilDelta ...
                 - obj.Diff_Epsilon;
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
    % Calculate and Assign Ramp Time
    % --------------------------------------------------------------------------
    function [obj,epsilon] = calculate_ramptime(obj)
        epsilon = obj.Diff_GradAmp./obj.Sys_GradSlew;
        obj.Diff_Epsilon = epsilon;
    end

    % --------------------------------------------------------------------------
    % Calculate and Assign b-value
    % --------------------------------------------------------------------------
    function [obj,bval] = calculate_bval(obj)
        bval = (1e-21)*(obj.C_GAMMA.*obj.Diff_GradAmp).^2 * get_btimeterm(obj);
        obj.Diff_bVal = bval;
    end
    

    % --------------------------------------------------------------------------
    % Calculate b time term
    % --------------------------------------------------------------------------
    function tt = get_btimeterm(obj)
        tt = ((obj.Diff_LilDelta.^2).*obj.Diff_BigDelta) ...
           - ((obj.Diff_LilDelta.^3)./3) ...
           + ((obj.Diff_Epsilon.^3)./30) ...
           - ((obj.Diff_Epsilon.^2).*obj.Diff_LilDelta./6);
    end

    % --------------------------------------------------------------------------
    % Query maximum possible b-value given current TE and TR
    % --------------------------------------------------------------------------
    function bval = getmax_bval(obj)
        obj.Diff_GradAmp = obj.Sys_GradMaxAmp;
        obj.Diff_Epsilon = getmax_ramp(obj);
        obj.Diff_LilDelta = getmax_lildelta(obj);
        obj.Diff_BigDelta = getmax_bigdelta(obj);
        [~,bval] = calculate_bval(obj);
    end

    % --------------------------------------------------------------------------
    % Manually Push Minimum Timings
    % --------------------------------------------------------------------------
    function obj = push_timings(obj)
        obj.Seq_TE = getmin_TE(obj);
        obj.Seq_TR = getmin_TR(obj);
    end

    % --------------------------------------------------------------------------
    % Design Diffusion Gradient that minimizes Gradient Amplitude
    % --------------------------------------------------------------------------
    function obj = designdiff_minG(obj,bval)
        % Takes a specified b-value and sets the values of BigDelta, LilDelta,
        % and GradAmp to minimize Gradient, while achieving the best diffusion
        % encoding

        % Check that the specified b value is actually obtainable
        if (bval > getmax_bval(obj))
            error(("Requested b-value of %d is too high.\n"+...
                   "Maximum b-value of the current sequence is %d.\n"+...
                   "\tTry changing TE first.\n"),...
                  bval,floor(getmax_bval(obj)));
        end

        % Current bval
        bcurr = 0;

        % Set Lil Delta to current allowed maximum
        obj.Diff_LilDelta = getmax_lildelta(obj);

        % Set Big Delta to current allowed maximum
        obj.Diff_BigDelta = getmax_bigdelta(obj);

        % Iterate through this process, until we get the desired values
        while abs(bval-bcurr) > 0.1

            % Calculate required gradient amplitude
            gradamp = (sqrt(bval).*(10^10.5)/(obj.C_GAMMA))/sqrt(get_btimeterm(obj));

            % Attempt to assign gradient amplitude
            obj.Diff_GradAmp = min(obj.Sys_GradMaxAmp,gradamp);

            % Calculate and update Epsilon
            obj = calculate_ramptime(obj);

            % Reset Lil Delta to new current allowed maximum
            obj.Diff_LilDelta = getmax_lildelta(obj);

            % Set Big Delta to current allowed maximum
            obj.Diff_BigDelta = getmax_bigdelta(obj);

            % Evaluate the actual b-value now
            [obj, bcurr] = calculate_bval(obj);

        end % while abs(bval-bcurr) > 0.1 

    end % function obj = designdiff_minG(obj,bval)

    % --------------------------------------------------------------------------
    % Design Diffusion Gradient that adheres to fixed Diffusion timings
    % --------------------------------------------------------------------------
    function obj = designdiff_fixD(obj,bval)
        % Takes a specified b-value and sets the values of GradAmp to achieve
        % the desired diffusion encoding, without changing Big Delta or Lil
        % Delta

        % Check that the specified b value is actually obtainable
        obj1 = obj;
        obj1.Diff_GradAmp = obj1.Sys_GradMaxAmp;
        obj1.Diff_Epsilon = getmax_ramp(obj1);
        [~,bmax] = calculate_bval(obj1);
        if (bval > bmax)
            error(("Requested b-value of %d is too high.\n"+...
                   "Maximum b-value of the current sequence is %d.\n"+...
                   "\tTry changing %s first.\n"),...
                  bval,bmax,sprintf('\x3b4'));
        end

        % Current bval
        bcurr = 0;

        % Iterate through this process, until we get the desired values
        while abs(bval-bcurr) > 0.1

            % Calculate required gradient amplitude
            gradamp = (sqrt(bval).*(10^10.5)/(obj.C_GAMMA))/sqrt(get_btimeterm(obj));

            % Attempt to assign gradient amplitude
            obj.Diff_GradAmp = min(obj.Sys_GradMaxAmp,gradamp);

            % Calculate and update Epsilon
            obj = calculate_ramptime(obj);

            % Evaluate the actual b-value now
            [obj, bcurr] = calculate_bval(obj);

        end % while abs(bval-bcurr) > 0.1

    end % function obj = designdiff_fixD(obj,bval)

    % --------------------------------------------------------------------------
    % Design Diffusion Gradient that minimizes Lil Delta (max Amplitude)
    % --------------------------------------------------------------------------
    function obj = designdiff_minD(obj,bval)
        % Takes a specified b-value and sets the values of LilDelta and BigDelta
        % to achieve the desired diffusion encoding, always using the maximum
        % gradient amplitude strength. There is probably a clever way of doing
        % this, but we're going to do it by a very basic grid search

        % Check that the specified b value is actually obtainable
        if (bval > getmax_bval(obj))
            error(("Requested b-value of %d is too high.\n"+...
                   "Maximum b-value of the current sequence is %d.\n"+...
                   "\tTry changing TE first.\n"),...
                  bval,floor(getmax_bval(obj)));
        end

        % Set the amplitude to max
        obj.Diff_GradAmp = obj.Sys_GradMaxAmp;

        % Calculate and set the epsilon
        obj = calculate_ramptime(obj);

        % Define range of Big Delta and Lil Delta
        vec_LilDelta = getmin_lildelta(obj):0.1:getmax_lildelta(obj);
        vec_BigDelta = getmin_bigdelta(obj):0.1:getmax_bigdelta(obj);

        % Make a grid
        [grid_LilDelta, grid_BigDelta] = ndgrid(vec_LilDelta,vec_BigDelta);

        % Calculate b-values
        grid_bval = calculate_bvalue(obj.Diff_GradAmp,grid_BigDelta,grid_LilDelta,obj.Diff_Epsilon);

        % Zero the ones that are invalid because LilDelta is too large
        grid_bval(grid_LilDelta > (grid_BigDelta - obj.Diff_Epsilon - obj.Sys_TimeRefoc)) = 0;

        % Zero the ones that are invalid because BigDelta is too large
        grid_bval(grid_BigDelta > (obj.Seq_TE - (obj.Sys_TimeExcite/2) ...
                                - (obj.Sys_TimeRead/2) - obj.Diff_Epsilon ...
                                - grid_LilDelta)) = 0;

        % Identify the minimum point
        [~,imin] = min(abs(grid_bval - bval),[],"all");

        % Identify and apply minimim Delta points
        obj.Diff_LilDelta = grid_LilDelta(imin);
        obj.Diff_BigDelta = grid_BigDelta(imin);

        % Evaluate the actual b-value now
        [obj, bcurr] = calculate_bval(obj);

        % Check that it worked
        if abs(bval-bcurr) > 0.1
            warning(("Requested b-value of %.2f was not obtained to high precision.\n"+...
                     "Best result was b = %.2f\n"),bval,bcurr);
        end

    end % function obj = designdiff_minD(obj,bval)


    % --------------------------------------------------------------------------
    % Plot the Sequence
    % --------------------------------------------------------------------------
    function fig_seq = plotseq(obj,fig_seq)

        % Create pulse shape for excitation pulse
        t_excite = linspace(0-obj.Sys_TimeExcite/2,obj.Sys_TimeExcite/2,100);
        s_excite = 0.66.*sinc(3*linspace(-1,1,100));

        % Create pulse shape for refocusing pulse
        t_refoc = linspace((obj.Seq_TE/2)-(obj.Sys_TimeRefoc/2),(obj.Seq_TE/2)+(obj.Sys_TimeRefoc/2),100);
        s_refoc = sinc(3*linspace(-1,1,100));

        % Calculate gradient amplitude as a function of the max
        relamp = obj.Diff_GradAmp./obj.Sys_GradMaxAmp;

        % Calculate the total time required for all the diffusion to play out
        totalenctime = obj.Diff_BigDelta + obj.Diff_LilDelta + obj.Diff_Epsilon;

        % Dead time
        totaldeadtime = obj.Seq_TE - totalenctime;

        % Position the gradients symmetrically around TE/2
        t_start1 = totaldeadtime/2;
        t_start2 = t_start1 + obj.Diff_BigDelta;

        % Create First Diffusion Gradient 
        t_diff1 = [t_start1,...
                   t_start1 + obj.Diff_Epsilon,...
                   t_start1 + obj.Diff_LilDelta,...
                   t_start1 + obj.Diff_LilDelta + obj.Diff_Epsilon];
        s_diff1 = [0, relamp, relamp, 0];

        % Create Second Diffusion Gradient
        t_diff2 = [t_start2,...
                   t_start2 + obj.Diff_Epsilon,...
                   t_start2 + obj.Diff_LilDelta,...
                   t_start2 + obj.Diff_LilDelta + obj.Diff_Epsilon];
        s_diff2 = [0, relamp, relamp, 0];

        % Create Readout Event
        t_readout = linspace(obj.Seq_TE-(obj.Sys_TimeRead/2),obj.Seq_TE+(obj.Sys_TimeRead/2),100);
        s_readout = 0.25.*sin(linspace(0,10*pi,100));

        % Concatenate
        t_rf = [t_excite, t_refoc, t_readout, obj.Seq_TE+obj.Sys_TimeRead];
        s_rf = [s_excite, s_refoc, s_readout, 0];


        % Manually create a new figure if no handle is supplied
        if nargin < 2
            fig_seq = figure(11);
        end

        % Figure Window
        set(fig_seq,'WindowStyle','normal','Position',[450,450,1100,300]);
        plot([-obj.Sys_TimeExcite,obj.Sys_TimeRead + obj.Seq_TE],[0,0],'k-');
        hold on;
        plot(t_rf,s_rf,'k');
        plot(t_diff1,s_diff1,'k-','LineWidth',2);
        plot(t_diff2,s_diff2,'k-','LineWidth',2);
        xlim([-obj.Sys_TimeExcite,obj.Sys_TimeRead + obj.Seq_TE]);
        ylim([-0.3,1.1]);
        xlabel('Time (ms)');

    end % function fig_seq = plotseq(obj)


% ------------------------------------------------------------------------------
% END OF CLASS DEFINITION
% ------------------------------------------------------------------------------
end % methods
end % classdef