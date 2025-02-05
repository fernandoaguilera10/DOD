function save_file2_HG

global num freq spl animal date freq_level data abr ABRmag w hearingStatus abr_out_dir abr_Stimuli ...
    AR_marker abr_time abr_FIG ChinCondition ChinFile ChinID date_abr today_date

ChinDir = abr_out_dir;
cd(ChinDir)
% check if previous files have been saved
if freq~=0
    file_check = dir(sprintf('*Q%s_%s_ABRpeaks_%dHz*.mat',num2str(animal),cell2mat(ChinCondition),freq));
else
    file_check = dir(sprintf('*Q%s_%s_ABRpeaks_click*.mat',num2str(animal),cell2mat(ChinCondition)));
end
filename = {file_check.name};
freq2=ones(1,num)*freq; replaced=0;
if ~isempty(filename) && ~isempty(abr_FIG.parm_txt(9).String) % Replace file contents if file exists and is active
    check = find(ismember(filename,abr_FIG.parm_txt(9).String) == 1);
    if ~isempty(check)
        overwrite_msg = questdlg(sprintf('Would you like to replace current peak file?\n\n%s\n',abr_FIG.parm_txt(9).String),...
            'Save Peak File', 'Yes', 'No','I dont know');
        answer = {overwrite_msg};
        if contains(answer, 'Yes') %Replaces file if file already exists
            if freq~=0
                prompt_peak_save = sprintf('\nReplacing File...\n\nSubject: Q%s \nStimulus: %.1f kHz\n',animal, freq/1000);
            else
                prompt_peak_save = sprintf('\nReplacing File...\n\nSubject: Q%s \nStimulus: Click\n',animal);
            end
            load(abr_FIG.parm_txt(9).String)
            if exist('abrs','var')
                waitbar(0,prompt_peak_save);
                pause(.5)
                close;
                if ismember(freq,abrs.thresholds(:,1))
                    abrs.thresholds(abrs.thresholds(:,1)==freq,:)=[];
                    abrs.z.par(abrs.z.par(:,1)==freq,:)=[];
                    abrs.z.score(abrs.z.score(:,1)==freq,:)=[];
                    abrs.amp(abrs.amp(:,1)==freq,:)=[];
                    abrs.x(abrs.x(:,1)==freq,:)=[];
                    abrs.y(abrs.y(:,1)==freq,:)=[];
                    abrs.waves(abrs.waves(:,1)==freq,:)=[];
                    replaced=1;
                end
                
                if size(abrs.x,2)<12
                    abrs.x=[abrs.x nan(size(abrs.x,1),12-size(abrs.x,2))];
                    abrs.y=[abrs.y nan(size(abrs.y,1),12-size(abrs.y,2))];
                end
                waitbar(0.5,prompt_peak_save);
                pause(1);
                close;
                abrs.thresholds = [abrs.thresholds; freq data.threshold data.amp_thresh -freq_level];
                abrs.z.par = [abrs.z.par; freq data.z.intercept data.z.slope];
                abrs.z.score = [abrs.z.score; freq2' spl' data.z.score' w'];
                abrs.amp = [abrs.amp; freq2' ABRmag];
                abrs.x = [abrs.x; freq2' spl' data.x'];
                abrs.y = [abrs.y; freq2' spl' data.y'];
                abrs.waves = [abrs.waves; freq2' spl' abr'];
                % Plotting structure
                abrs.plot.waveforms = abrs.waves(:,3:end);
                abrs.plot.waveforms_time = abr_time;
                abrs.plot.peak_latency = abrs.x(:,3:end);
                abrs.plot.peak_amplitude = abrs.y(:,3:end);
                abrs.plot.levels = abrs.x(:,2);
                abrs.plot.peaks = ["p1" "n1" "p2" "n2" "p3" "n3" "p4" "n4" "p5" "n5"];
                abrs.plot.freq = abrs.x(1,1);
                abrs.plot.threshold = data.threshold;
                abrs.plot.levels = spl';
                %HG ADDED 2/11/20
                abrs.AR_marker = AR_marker;
                filename_out = abr_FIG.parm_txt(9).String;
                save(filename_out, 'abrs','-append'); clear abrs;
            else
                abrs.thresholds = [freq data.threshold data.amp_thresh -freq_level];
                abrs.z.par = [freq data.z.intercept data.z.slope];
                abrs.z.score = [freq2' spl' data.z.score' w'];
                abrs.amp = [freq2' ABRmag];
                abrs.x = [freq2' spl' data.x'];
                abrs.y = [freq2' spl' data.y'];
                abrs.waves = [freq2' spl' abr'];
                % Plotting structure
                abrs.plot.waveforms = abrs.waves(:,3:end);
                abrs.plot.waveforms_time = abr_time;
                abrs.plot.peak_latency = abrs.x(:,3:end);
                abrs.plot.peak_amplitude = abrs.y(:,3:end);
                abrs.plot.levels = abrs.x(:,2);
                abrs.plot.peaks = ["p1" "n1" "p2" "n2" "p3" "n3" "p4" "n4" "p5" "n5"];
                abrs.plot.freq = abrs.x(1,1);
                abrs.plot.threshold = data.threshold;
                abrs.plot.levels = spl';
                abrs.AR_marker = AR_marker;
                idx = strfind(abr_FIG.parm_txt(9).String,'.mat');
                filename_out = [abr_FIG.parm_txt(9).String(1:idx-12-1)];
                save(filename_out, 'abrs','-append'); clear abrs;
            end
        elseif  contains(answer, 'No') || isempty(filename) || isempty(abr_FIG.parm_txt(9).String)%Creates new version file
            if freq~=0
                prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: %.1f kHz\n',animal, freq/1000);
            else
                prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: Click\n',animal);
            end
            waitbar(0,prompt_peak_save);
            pause(.5);
            close;
            abrs.thresholds = [freq data.threshold data.amp_thresh -freq_level];
            abrs.z.par = [freq data.z.intercept data.z.slope];
            abrs.z.score = [freq2' spl' data.z.score' w'];
            abrs.amp = [freq2' ABRmag];
            abrs.x = [freq2' spl' data.x'];
            abrs.y = [freq2' spl' data.y'];
            abrs.waves = [freq2' spl' abr'];
            % Plotting structure
            abrs.plot.waveforms = abrs.waves(:,3:end);
            abrs.plot.waveforms_time = abr_time;
            abrs.plot.peak_latency = abrs.x(:,3:end);
            abrs.plot.peak_amplitude = abrs.y(:,3:end);
            abrs.plot.levels = abrs.x(:,2);
            abrs.plot.peaks = ["p1" "n1" "p2" "n2" "p3" "n3" "p4" "n4" "p5" "n5"];
            abrs.plot.freq = abrs.x(1,1);
            abrs.plot.threshold = data.threshold;
            abrs.plot.levels = spl';
            [~,c] = size(filename);
            if ~isempty(filename)
                file_num = c + 1;
                filename3 = sprintf('%s%d',file_check(c).name(1:end-5),file_num);
                while exist(sprintf('%s%d',file_check(c).name(1:end-5),file_num),'file')
                    file_num = file_num + 1;
                    filename3 = strcat(file_check(c).name(1:end-5), file_num);
                end
                filename_out = filename3;
                save(filename_out,'abrs');
            end
            %HG ADDED 2/11/20
            abrs.AR_marker = AR_marker;
            waitbar(0.5,prompt_peak_save);
            pause(.5);
            close;
        end
    end
elseif ~isempty(filename) && isempty(abr_FIG.parm_txt(9).String) %Save new file if prior files exist
    if freq~=0
        prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: %.1f kHz\n',animal, freq/1000);
    else
        prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: Click\n',animal);
    end
    waitbar(0,prompt_peak_save);
    pause(.5);
    close;
    abrs.thresholds = [freq data.threshold data.amp_thresh -freq_level];
    abrs.z.par = [freq data.z.intercept data.z.slope];
    abrs.z.score = [freq2' spl' data.z.score' w'];
    abrs.amp = [freq2' ABRmag];
    abrs.x = [freq2' spl' data.x'];
    abrs.y = [freq2' spl' data.y'];
    abrs.waves = [freq2' spl' abr'];
    % Plotting structure
    abrs.plot.waveforms = abrs.waves(:,3:end);
    abrs.plot.waveforms_time = abr_time;
    abrs.plot.peak_latency = abrs.x(:,3:end);
    abrs.plot.peak_amplitude = abrs.y(:,3:end);
    abrs.plot.levels = abrs.x(:,2);
    abrs.plot.peaks = ["p1" "n1" "p2" "n2" "p3" "n3" "p4" "n4" "p5" "n5"];
    abrs.plot.freq = abrs.x(1,1);
    abrs.plot.threshold = data.threshold;
    abrs.plot.levels = spl';
    [~,c] = size(filename);
    if ~isempty(filename)
        file_num = c + 1;
        filename3 = sprintf('%s%d',file_check(c).name(1:end-5),file_num);
        while exist(sprintf('%s%d',file_check(c).name(1:end-5),file_num),'file')
            file_num = file_num + 1;
            filename3 = strcat(file_check(c).name(1:end-5), file_num);
        end
        filename_out = filename3;
        save(filename_out,'abrs');
    end
    %HG ADDED 2/11/20
    abrs.AR_marker = AR_marker;
    waitbar(0.5,prompt_peak_save);
    pause(.5);
    close;
else    %Save first file if no prior files exist
    if freq~=0
        filename2 = sprintf('Q%s_%s_ABRpeaks_%dHz',num2str(animal),cell2mat(ChinCondition),freq);
        prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: %.1f kHz\n',animal, freq/1000);
    else
        filename2 = sprintf('Q%s_%s_ABRpeaks_click',num2str(animal),cell2mat(ChinCondition));
        prompt_peak_save = sprintf('\nSaving New File...\n\nSubject: Q%s \nStimulus: Click\n',animal);
    end
    
    waitbar(0,prompt_peak_save);
    pause(.5);
    close;
    abrs.thresholds = [freq data.threshold data.amp_thresh -freq_level];
    abrs.z.par = [freq data.z.intercept data.z.slope];
    abrs.z.score = [freq2' spl' data.z.score' w'];
    abrs.amp = [freq2' ABRmag];
    abrs.x = [freq2' spl' data.x'];
    abrs.y = [freq2' spl' data.y'];
    abrs.waves = [freq2' spl' abr'];
    % Plotting structure
    abrs.plot.waveforms = abrs.waves(:,3:end);
    abrs.plot.waveforms_time = abr_time;
    abrs.plot.peak_latency = abrs.x(:,3:end);
    abrs.plot.peak_amplitude = abrs.y(:,3:end);
    abrs.plot.levels = abrs.x(:,2);
    abrs.plot.peaks = ["p1" "n1" "p2" "n2" "p3" "n3" "p4" "n4" "p5" "n5"];
    abrs.plot.freq = abrs.x(1,1);
    abrs.plot.threshold = data.threshold;
    abrs.plot.levels = spl';
    filename_out = [filename2 '_v1'];
    waitbar(0.5,prompt_peak_save);
    pause(.5);
    close;
    save(filename_out, 'abrs');
end
uiwait(msgbox(sprintf('\nFilename: %s\n\nDirectory: %s',filename_out,abr_out_dir),'ABR - PEAKS SAVED','modal'));
clear abrs;