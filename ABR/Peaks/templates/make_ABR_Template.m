ROOTdir = '/Volumes/FefeSSD/DOD';
Chins2Run='Q503';
Conds2Run = strcat('pre',filesep,'Baseline');
template_freq = 8000;  % Hz
template_level = 80;   % dB SPL
%% Analysis
cwd = pwd;
datapath = strcat(ROOTdir,filesep,'Data',filesep,Chins2Run,filesep,'ABR',filesep,Conds2Run);
template_flag = 'No';
if exist(datapath,'dir')
    all_datafiles = {dir(fullfile(datapath,'p*ABR*.mat')).name}';
    all_freqs = cellfun(@(x) erase(extractAfter(x,'ABR_'), '.mat'), all_datafiles, 'UniformOutput', false);
    all_freqs(strcmp(all_freqs,'click')) = {'0'};
    freqs = unique(str2double(all_freqs));
    for f = 1:length(freqs)
        lev = [];
        freqs_datafiles = all_datafiles(str2double(all_freqs) == template_freq);
        for d = 1:length(freqs_datafiles)
            cd(datapath);
            load(freqs_datafiles{d})
            abr_level = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
            if abr_level == template_level     % if template level matches ABR waveform level
                % Resample ABR p-file
                fs = 8e3;
                if iscell(x.AD_Data.AD_All_V{1})
                    abr_raw = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1})); % waveform with DC offset removed
                else
                    abr_raw = mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V))); % waveform with DC offset removed
                end
                abr = resample(abr_raw,fs,round(x.Stimuli.RPsamprate_Hz));
                abr = abr - mean(abr);
                t = x.Stimuli.CAP_Gating.XstartPlot_ms/1000:1/fs:x.Stimuli.CAP_Gating.XendPlot_ms/1000-1/fs;

                % Define frequency and level
                if x.Stimuli.clickYes
                    freq = 0;
                    freq_str = 'click';
                else
                    freq = x.Stimuli.freq_hz;
                    freq_str = [num2str(freq(z)), 'Hz'];
                end
                level_spl = round(x.Stimuli.MaxdBSPLCalib - x.Stimuli.atten_dB);

                % Define template filename
                template_name = ['template_',freq_str,'_',mat2str(level_spl),'dBSPL'];
                %% Pick Template Peaks Manually
                while strcmp(template_flag,'No')
                    figure(1);
                    plot(t, abr, 'k-', 'LineWidth', 3);
                    xlim([0,0.02]);
                    xlabel('Time (s)');
                    set(gcf, 'Position', get(0, 'Screensize'));
                    hold on;
                    % Prompt the user to select waves: I, III, and V (6 points)
                    num_waves = 3;
                    num_peaks = num_waves*2;
                    points = zeros(num_peaks, 3);
                    point_names = {'P1', 'N1', 'P3', 'N3', 'P5', 'N5'};
                    for i = 1:num_peaks
                        title(['ABR Template | ',freq_str,' | ',mat2str(template_level),' dB SPL'])
                        subtitle(['Choose ', point_names{i}]);
                        set(gca,'FontSize',25);
                        [x_i, y_i] = ginput(1); % Get the coordinates from user input
                        [~, index] = min(abs(t - x_i) + abs(abr - y_i));
                        x_i = t(index);
                        y_i = abr(index);
                        plot(x_i, y_i, 'ro', 'MarkerSize', 12,'LineWidth', 3); % Plot the selected point
                        points(i, :) = [x_i, y_i, index]; % Store the point in the matrix
                        text(x_i, y_i, point_names{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right','FontSize',25); % Label the point
                    end
                    hold off;
    
    
                    template_flag = questdlg('Are you satisfied with template?','Save Template','Yes','No','Yes');
                    if strcmp(template_flag,'Yes')
                        % Save template
                        outpath = strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR',filesep,'Peaks',filesep,'templates');
                        cd(outpath);
                        save(template_name, 'points','t','abr','point_names');
                        close figure 1;
                        return;
                    else
                        clf;
                    end
                end
            end
            clear x;
        end
    end
end