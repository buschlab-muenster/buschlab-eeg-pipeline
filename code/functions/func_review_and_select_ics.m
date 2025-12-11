function EEG = func_review_and_select_ics(EEG, flagged_comps, show_all_comps, classifier_name)
% func_review_and_select_ics - Integrated ICA component review and selection
%
% This function combines pop_viewprops and pop_selectcomps functionality:
% - Shows component topographies with ICLabel classifications
% - Click component numbers to toggle rejection (red=reject, green=accept)
% - Click "Details" buttons to view component properties
%
% Inputs:
%   EEG              - EEGLAB EEG structure with ICA decomposition
%   flagged_comps    - Component indices pre-flagged for rejection (optional)
%   show_all_comps   - true=show all, false=show only flagged (default: false)
%   classifier_name  - Classifier to display (default: 'ICLabel')
%
% Output:
%   EEG - Updated EEG structure with modified reject.gcompreject
%
% Usage:
%   EEG = func_review_and_select_ics(EEG);  % Review flagged components
%   EEG = func_review_and_select_ics(EEG, [], true);  % Review all components
%
% Author: Created for buschlab-eeg-pipeline

%% Input handling
if nargin < 2 || isempty(flagged_comps)
    flagged_comps = find(EEG.reject.gcompreject == 1);
end
if nargin < 3 || isempty(show_all_comps)
    show_all_comps = false;
end
if nargin < 4 || isempty(classifier_name)
    classifier_name = 'ICLabel';
end

% Determine which components to display
if show_all_comps
    comps_to_show = 1:size(EEG.icaweights, 1);
else
    if isempty(flagged_comps)
        fprintf('No components flagged. Showing all components.\n');
        comps_to_show = 1:size(EEG.icaweights, 1);
    else
        comps_to_show = flagged_comps;
    end
end

% Initialize rejection vector if needed
if isempty(EEG.reject.gcompreject)
    EEG.reject.gcompreject = zeros(size(EEG.icawinv, 2), 1);
end

%% Setup figure
fprintf('\n========================================\n');
fprintf('ICA Component Review and Selection\n');
fprintf('========================================\n');
fprintf('Total components: %d\n', size(EEG.icaweights, 1));
fprintf('Currently flagged: %d\n', sum(EEG.reject.gcompreject));
fprintf('Displaying: %d components\n', length(comps_to_show));
fprintf('========================================\n\n');

COLREJ = [1 0.6 0.6];      % Red for rejected
COLACC = [0.75 1 0.75];    % Green for accepted
BACKCOLOR = [0.8 0.8 0.8];
PLOTPERFIG = 35;

% Handle multiple figures if too many components
if length(comps_to_show) > PLOTPERFIG
    fprintf('More than %d components. Creating multiple windows...\n', PLOTPERFIG);
    for index = 1:PLOTPERFIG:length(comps_to_show)
        end_idx = min(length(comps_to_show), index + PLOTPERFIG - 1);
        EEG = func_review_and_select_ics(EEG, comps_to_show(index:end_idx), false, classifier_name);
    end
    return;
end

% Calculate grid layout
column = ceil(sqrt(length(comps_to_show))) + 1;
rows = ceil(length(comps_to_show) / column);

% Create figure
figtag = ['ic_review_' num2str(rand)];
fig = figure('Name', ['ICA Component Review (Dataset: ' EEG.setname ')'], ...
             'Tag', figtag, ...
             'NumberTitle', 'off', ...
             'Color', BACKCOLOR, ...
             'MenuBar', 'none', ...
             'CloseRequestFcn', @cancel_callback);

% Set figure size
pos = get(fig, 'Position');
set(fig, 'Position', [pos(1) 20 800/7*column 600/5*rows*1.3]);

% Calculate subplot parameters
incx = 120;
incy = 110;
sizewx = 100 / column;
if rows > 2
    sizewy = 90 / rows;
else
    sizewy = 80 / rows;
end

axes('Position', [0 0 1 1], 'Visible', 'off');
pos = get(gca, 'position');
q = [pos(1) pos(2) 0 0];
s = [pos(3) pos(4) pos(3) pos(4)] ./ 100;

% Check if we should plot electrodes
plotelec = EEG.nbchan <= 64;
if ~plotelec
    fprintf('More than 64 channels: electrode locations not shown\n');
end

%% Plot each component
count = 1;
button_handles = [];
for ri = comps_to_show
    % Calculate position
    X = mod(count-1, column) / column * incx - 10;
    Y = (rows - floor((count-1) / column)) / rows * incy - sizewy * 1.3;

    % Plot topoplot
    ha = axes('Units', 'Normalized', 'Position', [X Y sizewx sizewy].*s+q);
    if plotelec
        topoplot(EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', 'off', ...
                 'style', 'fill', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
    else
        topoplot(EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', 'off', ...
                 'style', 'fill', 'electrodes', 'off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
    end

    % Add ICLabel classification if available
    if isfield(EEG.etc, 'ic_classification') && isfield(EEG.etc.ic_classification, classifier_name)
        [prob, classind] = max(EEG.etc.ic_classification.(classifier_name).classifications(ri, :));
        class_label = EEG.etc.ic_classification.(classifier_name).classes{classind};
        t = title(sprintf('%s: %.1f%%', class_label, prob*100), 'FontSize', 8);
        set(t, 'Position', get(t, 'Position') .* [1 -1.2 1]);
    end
    axis square;

    % Create toggle button (for reject/accept)
    btn_toggle = uicontrol(fig, 'Style', 'pushbutton', ...
                          'Units', 'Normalized', ...
                          'Position', [X Y+sizewy sizewx sizewy*0.15].*s+q, ...
                          'String', sprintf('%d', ri), ...
                          'Tag', sprintf('toggle_%d', ri), ...
                          'FontWeight', 'bold', ...
                          'UserData', ri, ...
                          'Callback', {@toggle_component, ri});

    % Set button color based on rejection status
    if EEG.reject.gcompreject(ri)
        set(btn_toggle, 'BackgroundColor', COLREJ);
    else
        set(btn_toggle, 'BackgroundColor', COLACC);
    end

    % Create details button (small button below the toggle)
    btn_details = uicontrol(fig, 'Style', 'pushbutton', ...
                           'Units', 'Normalized', ...
                           'Position', [X Y+sizewy+sizewy*0.16 sizewx sizewy*0.10].*s+q, ...
                           'String', 'Details', ...
                           'FontSize', 7, ...
                           'Callback', {@show_details, ri});

    button_handles = [button_handles; btn_toggle];
    count = count + 1;
end

%% Add control buttons at bottom
% Cancel button
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cancel', ...
         'Units', 'Normalized', 'BackgroundColor', BACKCOLOR, ...
         'Position', [-10 -10 15 sizewy*0.25].*s+q, ...
         'Callback', @cancel_callback);

% Help text
uicontrol(fig, 'Style', 'text', 'String', ...
         'Click component number to toggle reject/accept. Click Details to view properties.', ...
         'Units', 'Normalized', 'BackgroundColor', BACKCOLOR, ...
         'Position', [10 -10 60 sizewy*0.25].*s+q, ...
         'HorizontalAlignment', 'center');

% OK button
uicontrol(fig, 'Style', 'pushbutton', 'String', 'OK', ...
         'Units', 'Normalized', 'BackgroundColor', BACKCOLOR, ...
         'Position', [75 -10 15 sizewy*0.25].*s+q, ...
         'Callback', @ok_callback);

fprintf('Figure created. Click component numbers to toggle rejection.\n');
fprintf('Click "Details" to view component properties.\n');
fprintf('Click OK when done, or Cancel to discard changes.\n\n');

% Store EEG in figure userdata
setappdata(fig, 'EEG', EEG);
setappdata(fig, 'button_handles', button_handles);
setappdata(fig, 'cancelled', false);
setappdata(fig, 'original_reject', EEG.reject.gcompreject);

% Wait for user to close figure
uiwait(fig);

% Retrieve results if figure still exists
if ishandle(fig)
    if ~getappdata(fig, 'cancelled')
        EEG = getappdata(fig, 'EEG');
        fprintf('\nComponent review completed.\n');
        fprintf('Components marked for rejection: %d\n', sum(EEG.reject.gcompreject));
        removed_comps = find(EEG.reject.gcompreject);
        if ~isempty(removed_comps)
            fprintf('Rejected ICs: %s\n', num2str(removed_comps'));
        end
    else
        fprintf('\nOperation cancelled. No changes made.\n');
    end
    delete(fig);
end

%% Nested callback functions

    function toggle_component(src, ~, comp_idx)
        % Toggle rejection status for this component
        EEG = getappdata(gcbf, 'EEG');

        % Toggle the rejection status
        EEG.reject.gcompreject(comp_idx) = ~EEG.reject.gcompreject(comp_idx);

        % Update button color
        if EEG.reject.gcompreject(comp_idx)
            set(src, 'BackgroundColor', COLREJ);
        else
            set(src, 'BackgroundColor', COLACC);
        end

        % Save updated EEG
        setappdata(gcbf, 'EEG', EEG);
    end

    function show_details(~, ~, comp_idx)
        % Show detailed properties for this component
        EEG = getappdata(gcbf, 'EEG');

        % Call EEGLAB's pop_prop function
        try
            % Store in base workspace temporarily for pop_prop
            assignin('base', 'EEG_temp', EEG);
            evalin('base', sprintf('pop_prop(EEG_temp, 0, %d, NaN, {''freqrange'', [1 50]});', comp_idx));
        catch ME
            fprintf('Error showing component details: %s\n', ME.message);
        end
    end

    function ok_callback(~, ~)
        % User clicked OK - accept changes
        setappdata(gcbf, 'cancelled', false);
        uiresume(gcbf);
    end

    function cancel_callback(~, ~)
        % User clicked Cancel or closed window - discard changes
        EEG = getappdata(gcbf, 'EEG');
        original_reject = getappdata(gcbf, 'original_reject');
        EEG.reject.gcompreject = original_reject;
        setappdata(gcbf, 'EEG', EEG);
        setappdata(gcbf, 'cancelled', true);
        uiresume(gcbf);
    end

end
