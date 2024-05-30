function datafile = load_files(path,filename)
    cwd = pwd;
    cd(path);
    datafile = dir(fullfile(cd,filename));
    if length(datafile) < 1 || isempty(datafile)
        fprintf('No files for this subject...Quitting.\n')
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
end