% Find files under given directory. If not found, directory will be created
function output = search_files(directory,filename)
% Check if directory exists
if ~exist(directory, 'dir') %if data directory does not exists
    output.files = [];
    output.dir = [];
elseif exist(directory, 'dir')  %if directory exists
    files = dir(fullfile(directory,filename));
    output.files = files;
    output.dir = directory;
end
end