% Define directory paths
% ROOTdir = directory with your project
% CODEdir = directory with MATLAB files (Github)
% DATAdir = directory with data to analyze

function [DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,EXPname2)
DATAdir = strcat(ROOTdir,filesep,'Data');
OUTdir = strcat(ROOTdir,filesep,'Analysis');
CODEdir = strcat(ROOTdir,filesep,'Code Archive',filesep,EXPname,filesep,EXPname2);
% Check if directories exist
directories = {ROOTdir, DATAdir, OUTdir, CODEdir};
directories_name = {'ROOT','DATA','OUT','CODE'};
counter = 0;
for i = 1:numel(directories)
    cur_dir = directories{i};
    cur_dir_name = directories_name{i};
    if exist(cur_dir, 'dir')
        fprintf('\n%s directory exists.',cur_dir_name);
    else
        fprintf('\n%s directory does not exists.',cur_dir_name);
        counter = counter + 1;
    end
end
if counter == 0
    % Display the directories
    clc;
    uiwait(msgbox('All directories loaded succesfully','Loaded Directories','help'));
    fprintf('ROOT:\t %s',ROOTdir);
    fprintf('\nDATA:\t %s',DATAdir);
    fprintf('\nOUT:\t %s',OUTdir);
    fprintf('\nCODE:\t %s\n',CODEdir);
else
    fprintf('\n\n.');
    uiwait(msgbox('ERROR: At least one directory was not found','Loaded Directories','error'));
end
end
