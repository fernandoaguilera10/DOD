function file_out = load_files(path,filename,file_type,datafile)
    cwd = pwd;
    if exist(path,'dir')
        cd(path);
        file_out = dir(fullfile(cd,filename));
        if length(file_out) < 1 || isempty(file_out)
            fprintf('No analyzed files for this subject.\n')
            cd(cwd);
            return
        elseif size(file_out,1) > 1
            switch file_type
                case 'data'
                    fprintf('More than 1 data file. Check this is correct file!\n');
                    file_out = uigetfile(filename);
                case 'calib'
                    calibFiles = dir(filename);
                    % Extract calibration p-numbers
                    calibNums = nan(numel(calibFiles),1);
                    for i = 1:numel(calibFiles)
                        tok = regexp(calibFiles(i).name, 'p(\d+)', 'tokens');
                        calibNums(i) = str2double(tok{1}{1});
                    end
                    % Extract data p-number
                    dataFiles = dir(datafile);
                    tok = regexp(dataFiles(1).name, 'p(\d+)', 'tokens');
                    dataNum = str2double(tok{1}{1});
                    valid_idx = calibNums < dataNum;
                    % Pick the closest earlier calibration
                    [~, idx] = max(calibNums(valid_idx));
                    file_out = calibFiles(idx).name;
            end
        elseif size(file_out,1) == 1
            file_out = file_out.name;
        end
        fprintf('File: %s\n',file_out);
        cd(cwd);
    else
        fprintf('%s was not found.\n',path);
        file_out = [];
    end
end