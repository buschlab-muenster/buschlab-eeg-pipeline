% eegplugin_NEAR() - a wrapper to plug-in NEAR pipeline into EEGLAB
% 
% Usage:
%   >> eegplugin_NEAR(fig,try_strings,catch_strings);
%
%   see also: pop_NEAR.m, NEAR_getBadChannels.m

% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it


% History:
% 05/26/2021 ver 0.0 by Velu Prabhakar Kumaravel. Created.
% 09/16/2023 ver 0.1 by Velu Prabhakar Kumaravel. Added GitHub Repository.

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% CITATION: If you use this toolbox, please cite 
% 1) Kumaravel et al., "NEAR: An artifact removal pipeline for human
% newborn EEG data.", JDCN (SI: EEG Methods of Developmental Cognitive
% Neuroscientists), 2022)
% 2) If you use LOF, please also cit Blue Bird (2022). Density-based Outlier Detection Algorithms (https://github.com/BlueBirdHouse/DDoutlier), GitHub. Retrieved January 28, 2022.


function vers = eegplugin_NEAR(fig, try_strings, catch_strings)

vers = 'NEAR_ChannelRejection1.0';
cmd = [ try_strings.check_data ...
        '[EEG,EEG,CURRENTSET,LASTCOM] = pop_NEAR(ALLEEG,EEG,CURRENTSET);' ...
        catch_strings.new_and_hist ];

    toolsmenu = findobj(fig, 'tag', 'tools');
    uimenu( toolsmenu, 'label', 'NEAR - Channel Rejection', 'userdata', 'startup:off;epoch:off;study:on', ...
    'callback', cmd);




