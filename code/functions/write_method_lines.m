function write_method_lines(cfg, varargin)
% Writes small lines that can serve as building blocks for method section.
% Takes the cfg as input and parses lines into a set txt-file depending on
% what variables have been passed on.
% Should be used like this:
%
%   write_method_lines(cfg, 'rereferencing', 1, ...)
%
% Required arguments:
% - cfg               the cfg file that was used in the processing. will
%                     contain all information regarding parameters etc.
% Optional arguments:
% - 'rereferencing'   put 1 if rereferencing has been performed.
% - ''
%
% -------------------------------------------------------------------------

% parser for getting input variables
p = inputParser;
addRequired(p, 'cfg', @isstruct);
addParameter(p, 'rereferencing', 0, @isscalar);
addParameter(p, 'lp_filtering', 0, @isscalar);
addParameter(p, 'hp_filtering', 0, @isscalar);
addParameter(p, 'epoching', 0, @isscalar);
parse(p, cfg, varargin{:});

% extract Input
cfg = p.Results.cfg;
methods = p.Results;

% get txt file and check if already existing
filename = fullfile(cfg.dir.qualitycheck,'method_lines.txt');
fileExists = exist(filename, 'file') == 2;

% open file and write header for first opening as well as date
fid = fopen(filename, 'a');
if ~fileExists
    fprintf(fid, '====================\n');
    fprintf(fid, 'Method-Section Lines\n');
end
fprintf(fid, '--------------------\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));

% -------------------------------------------------------------------------
% For each method, write now the textblock that serves as
% method-section template
% -------------------------------------------------------------------------

% re-referencing
if methods.rereferencing
    fprintf(fid, ['The data was rereferenced to channel ' num2str(cfg.prep.reref_chan) '\n']);
end

% filtering. Use func_import_filter.m as reference for exact process
if methods.lp_filtering
    fprintf(fid, ['A lowpass filter of '  num2str(cfg.prep.lp_filter_limit) 'Hz has been applied to the data \n']);
    fprintf(fid, ['For this, a FIR-filter using the blackman window has been used \n']);

    % [m, ~] = pop_firwsord('blackman', EEG.srate, cfg.lp_filter_tbandwidth);
    % [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.lp_filter_limit, 'ftype',...
    %     'lowpass', 'wtype', 'blackman', 'forder', m);
    % EEG = eegh(com, EEG);
end
if methods.hp_filtering
    fprintf(fid, ['A highpass filter of '  num2str(cfg.prep.hp_filter_limit) 'Hz has been applied to the data \n']);
    switch(cfg.prep.hp_filter_type)
        case {'butterworth', 'butter'} 
            fprintf(fid, ['For this, a 2nd order butterworth-filter has been used \n']);

            %EEG  = pop_basicfilter( EEG, 1:EEG.nbchan, ...
            %    'Cutoff',  cfg.hp_filter_limit, ...
            %    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );

        case('kaiser')
            fprintf(fid, ['For this, a FIR-filter using the kaiser window has been used \n']);

            % m = pop_firwsord('kaiser', EEG.srate, cfg.hp_filter_tbandwidth, cfg.hp_filter_pbripple);
            % beta = pop_kaiserbeta(cfg.hp_filter_pbripple);
            % 
            % [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.hp_filter_limit, ...
            %     'ftype', 'highpass', 'wtype', 'kaiser', ...
            %     'warg', beta, 'forder', m);

        case('eegfiltnew')
            fprintf(fid, ['For this, a FIR-filter using the hamming window has been used \n']);

            %[EEG, com] = pop_eegfiltnew(EEG, cfg.hp_filter_limit, 0);
            %   >> [EEG, com, b] = pop_eegfiltnew(EEG, locutoff, hicutoff, filtorder,
            %                                     revfilt, usefft, plotfreqz, minphase);

    end
end

if methods.epoching

end

% close file
fclose(fid);

% show message at end of writing
disp('Method section lines written to method_lines.txt inside quality folder');
end
% END OF FILE