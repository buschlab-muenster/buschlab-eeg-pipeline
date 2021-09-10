function D = get_design(designidx)
% D = GET_DESIGN(designidx) gets & defines designs for EEG analysis.
%   
% Functions handling the design information will select the appropriate
% trials from the EEG datasets using the information stored in the
% EEG.event structure, such as correctness, stimulus type, etc.
%
% designidx (optional input): if given, the function will return only the
%   design of this index. Default is to return all designs defined in this
%   file.
% d.factor_names:   refers to the information stored in the EEG.event
%   structure. Thus, defining a factor with factor name "Correct" requires
%   that there be an event field EEG.event.Correct! 
% d.factor_values:  defines
%   which values/levels of factor_name you are interested in. Defining the
%   factor values as {1 0} requires that EEG.event.Correct actually takes
%   values of 0 and 1.
%   This is crucial. If you specify ranges (like 1:10), it won't match 1.1!
%   You can specify function handles that will match anything you desire.
%   For numerical variables, you can require to combine two possible values
%   into one factor via vectors (like {1, [0,2]} to combine 0 and 2.
%   FOR STRINGS, just create a cell with strings. If you want to combine
%   two strings in one factor, use a function handle that will match both
%   strings. (see below for examples for all of the above)
% d.factor_names_label (optional): sometimes the fieldnames in EEG.event are ugly
%   of even not descriptive. In order to facilitate later processing and
%   plotting of the results, you can choose a nicer string here.
% d.factor_values_label (optional): likewise, values in EEG.event are often
%   not informative. What does EEG.event.cue_type = 1 mean. You can define an
%   informative string here.

D(1).factor_names  = {'target_cue_w', 'saccade_cue_w', 'response_correct'};
D(1).factor_names_label = {'memcue', 'sacccue', 'response_correct'};
D(1).factor_values = {{'MemR', 'MemL', 'MemX'},...
    {'SaccR', 'SaccL'}, {1 0}};
D(1).factor_values_label = {{'right', 'left', 'nomem'},...
    {'right', 'left'}, {'correct', 'wrong'}};

% Make sure we return only the desired designs.
if nargin~=0
    D = D(designidx);
end

return

 
%%------------------------------------------------------------
% EXAMPLES
% These should not be actually execute by the function because
% they are located after the return statement.
% ------------------------------------------------------------
D(99).factor_names  = {'cue_dir', 'report_correct'};
D(99).factor_values = { {1 2 3}, {0 1} };
D(99).factor_names_label = {'cue direction', 'accuracy'};
D(99).factor_values_label = { {'valid', 'invalid', 'neutral'}, {'error', 'correct'} };

% You can use the syntax:
% d.factor_values = {{[1:320],[640:960]}};
% If the factor represents a continuous numerical variable such as trial
% number or reaction times, you may want to combine value RANGES, such as
% early vs. late trials or fast vs. slow responses. 
% DANGERZONE: Elektro-Pipe will internally round your data to integers in
% order to match the range. This does not make sense for many kind of data.
% For instance, hitrates are usually between 0 and 1. If you want to split
% by hitrate, the result will obviusly be false. In most cases, it's better
% to define a logical statement as a function handle (see below.)
D(99).factor_names  = {'SetSize', 'Trial'};
D(99).factor_values = { {1 2}, {[1:320], [640:960]} };

% You can use the syntax:
% d.factor_values = {{@(x) x >=1 & x<=320}, {@(x) x >= 640 & x <= 960}};
% Any function that will match the desired trials is possible. The
% entered string will be evaluated, replacing 'x' with the factor values in
% the data.
D(99).factor_names  = {'SetSize', 'Trial'};
D(99).factor_values = { {1 2}, {{@(x) x >=1 & x<=320}, {@(x) x >= 640 & x <= 960}}};


% to match strings or multiple strings (logic function handles)
D(1).factor_names  = {'hitRate', 'RemKnow'}; 
D(1).factor_values = {...
    {@(x) x >= 0 & x < 0.5, @(x) x >= 0.5 & x < 0.74, @(x) x >= 0.74},...
    {'remember', 'know', @(x) ismember(x, {'foreign', 'new'})} }; 

% You can use the syntax:
% d.factor_values = {{1 2 [3 4]}}
% The square brackets mean: look for trials with values of 1 and 2 in
% EEG.event and treat them as the same factor level. This would be useful
% for example when subjects use a 4-point rating scale, but rarely use
% levels 3 and 4, so that you want to combine these rating levels. 
% DON'T DO THIS FOR STRINGS!
D(99).factor_names  = {'ismasked', 'hemifield', 'rating'};
D(99).factor_values = { {0 1}, {1 2}, {1 2 [3 4]} };