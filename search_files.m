% Find files under given directory. If not found, directory will be created
function output = search_files(subject,condition,data_directory,out_directory)
if nargin < 1
        uiwait(msgbox('ERROR: At least one input is required','Analysis Type','error'));
end
% Check if directory exists
if ~exist(data_directory, 'dir') %if data directory does not exists
    dir_msg = sprintf('ERROR: Data directory does not exist for %s (%s)',subject,condition);
    %uiwait(msgbox(dir_msg,'Analysis Type','error'));
    output.files = [];
    output.dir = [];
elseif exist(data_directory, 'dir')  %if directory exists
    files = dir(fullfile(data_directory, '*.mat'));  % extract .mat files only
    output.files = files;
    output.dir = out_directory;
    if ~exist(out_directory, 'dir')
        fprintf('\nCreating analysis directory for %s (%s)...\n',subject, condition);
        mkdir(out_directory);
    end
end
end