% APAT_app  —  Auditory Physiology Analysis Tool
%
% Open this file and press F5 (or click Run) to launch the application.
% No other files need to be opened.

% Add private/ to path so internal helpers are accessible during the session
addpath(fullfile(fileparts(mfilename('fullpath')), 'private'));

% Launch the app — feval resolves to the @APAT_app class constructor
feval('APAT_app');
