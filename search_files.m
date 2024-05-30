% Find files under given directory. If not found, directory will be created
function output = search_files(subject,condition,directory)
if nargin < 1
        uiwait(msgbox('ERROR: At least one input is required','Analysis Type','error'));
end
% Check if directory exists
if ~exist(directory, 'dir') %if directory does not exists
    dir_msg = sprintf('ERROR: Directory does not exist for %s (%s)',subject,condition);
    uiwait(msgbox(dir_msg,'Analysis Type','error'));
    output.files = [];
    output.dir = directory;
    fprintf('\nCreating directory for %s (%s)...\n',subject, condition);
    mkdir(directory);
elseif exist(directory, 'dir')  %if directory exists
    files = dir(fullfile(directory, '*.mat'));  % extract .mat files only
    output.files = files;
    output.dir = directory;
end
end