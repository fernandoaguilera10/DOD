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
                        % Several raw recordings: remembered choice, the one the
                        % existing results used, or the Setup rule (Options →
                        % Multiple Recordings); asks only with Ask Once / Ask
                        % Every Time (choose_recording)
                        file_names = {file_out.name};
                        file_out = choose_recording(path, file_names, filename);
                    end
                case 'calib'
                    % Several calibrations: always the one recorded closest
                    % before the data file (choose_recording kind 'calib')
                    if nargin < 4, datafile = ''; end
                    file_out = choose_recording(path, {file_out.name}, filename, 'calib', datafile);
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