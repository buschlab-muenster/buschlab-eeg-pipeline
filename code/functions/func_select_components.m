function reject_flags = func_select_components(EEG, initial_flags)
% FUNC_SELECT_COMPONENTS - Simple GUI to select ICA components for rejection
%
% Usage:
%   reject_flags = func_select_components(EEG, initial_flags)
%
% Inputs:
%   EEG           - EEGLAB dataset structure with ICA decomposition
%   initial_flags - Vector of 0s and 1s indicating initially flagged components
%
% Output:
%   reject_flags  - Updated vector of rejection flags
%
% This function provides a simple checkbox interface without relying on
% EEGLAB global variables.
%
% How it works:
%   1. Takes the current EEG.reject.gcompreject as input (initial_flags)
%   2. Shows the GUI with checkboxes reflecting the current state
%   3. Updates the flags based on your checkbox selections
%   4. Returns the updated rejection flags when you click "Accept"
%   5. Assigns the returned flags back to EEG.reject.gcompreject

    ncomps = size(EEG.icaweights, 1);
    reject_flags = initial_flags;

    % Create figure
    fig = figure('Name', 'Select Components to Reject', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'Toolbar', 'none', ...
                 'Position', [100 100 400 600], ...
                 'CloseRequestFcn', @close_callback);

    % Instructions
    uicontrol('Style', 'text', ...
              'String', sprintf('Select components to REJECT (%d total)', ncomps), ...
              'Position', [10 560 380 30], ...
              'FontSize', 12, ...
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'center');

    % Create scrollable panel for checkboxes
    scroll_panel = uipanel('Parent', fig, ...
                           'Position', [0.05 0.15 0.9 0.75], ...
                           'BorderType', 'line');

    % Create checkboxes for each component
    checkbox_handles = zeros(ncomps, 1);
    nrows = ceil(ncomps / 5);
    for i = 1:ncomps
        row = ceil(i / 5);
        col = mod(i-1, 5) + 1;

        x_pos = 10 + (col-1) * 70;
        y_pos = 550 - (row-1) * 30;

        checkbox_handles(i) = uicontrol('Parent', scroll_panel, ...
                                        'Style', 'checkbox', ...
                                        'String', sprintf('IC %d', i), ...
                                        'Value', initial_flags(i), ...
                                        'Position', [x_pos y_pos 60 20], ...
                                        'Callback', @checkbox_callback);
    end

    % Buttons
    uicontrol('Style', 'pushbutton', ...
              'String', 'Accept', ...
              'Position', [50 20 100 30], ...
              'FontSize', 11, ...
              'Callback', @accept_callback);

    uicontrol('Style', 'pushbutton', ...
              'String', 'Cancel', ...
              'Position', [160 20 100 30], ...
              'FontSize', 11, ...
              'Callback', @cancel_callback);

    uicontrol('Style', 'pushbutton', ...
              'String', 'Select All', ...
              'Position', [270 20 60 30], ...
              'FontSize', 9, ...
              'Callback', @selectall_callback);

    uicontrol('Style', 'pushbutton', ...
              'String', 'Clear All', ...
              'Position', [335 20 55 30], ...
              'FontSize', 9, ...
              'Callback', @clearall_callback);

    % Wait for user to close the figure
    uiwait(fig);

    % Nested callback functions
    function checkbox_callback(src, ~)
        % Update reject_flags when checkbox is toggled
        comp_num = str2double(strrep(src.String, 'IC ', ''));
        reject_flags(comp_num) = src.Value;
    end

    function accept_callback(~, ~)
        uiresume(fig);
        close(fig);
    end

    function cancel_callback(~, ~)
        reject_flags = initial_flags; % Revert to initial flags
        uiresume(fig);
        close(fig);
    end

    function close_callback(~, ~)
        reject_flags = initial_flags; % Revert if closed without accepting
        delete(fig);
    end

    function selectall_callback(~, ~)
        for j = 1:ncomps
            set(checkbox_handles(j), 'Value', 1);
            reject_flags(j) = 1;
        end
    end

    function clearall_callback(~, ~)
        for j = 1:ncomps
            set(checkbox_handles(j), 'Value', 0);
            reject_flags(j) = 0;
        end
    end

end
