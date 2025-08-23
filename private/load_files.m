function datafile = load_files(path,filename)
    cwd = pwd;
    if exist(path,'dir')
        cd(path);
        datafile = dir(fullfile(cd,filename));
        if length(datafile) < 1 || isempty(datafile)
            fprintf('No analyzed files for this subject.\n')
            cd(cwd);
            return
        elseif size(datafile,1) > 1
            fprintf('More than 1 data file. Check this is correct file!\n');
            datafile = uigetfile(filename);
        elseif size(datafile,1) == 1
            datafile = datafile.name;
        end
        fprintf('File: %s\n',datafile);
        cd(cwd);
    else
        fprintf('%s was not found.\n',path);
        datafile = [];
    end
end