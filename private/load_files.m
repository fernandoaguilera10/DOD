function file_out = load_files(path,filename,file_type,datafile,auto_select)
    if nargin < 5, auto_select = false; end
    cwd = pwd;
    if exist(path,'dir')
        cd(path);
        files_all = dir(fullfile(cd,filename));
        file_out = files_all(~contains({files_all.name}, '._'));
        if length(file_out) < 1 || isempty(file_out)
            fprintf('No analyzed files for this subject.\n')
            cd(cwd);
            return
        elseif size(file_out,1) > 1
            switch file_type
                case 'data'
                    if auto_select
                        % Auto-select the most recently modified file (e.g. just created by reanalyze)
                        [~, newest_idx] = max([file_out.datenum]);
                        file_out = file_out(newest_idx).name;
                        fprintf('Multiple files found — auto-selected newest: %s\n', file_out);
                    else
                        fprintf('More than 1 data file found — prompting for selection.\n');
                        file_names = {file_out.name};
                        file_out = pick_datafile(file_names, 'Select data file');
                    end
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