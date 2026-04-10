function create_abr_template(ROOTdir, subject, condition, template_freq, template_level, TEMPLATEdir, done_callback)
%CREATE_ABR_TEMPLATE  Interactive ABR template creation.
%
%   create_abr_template(ROOTdir, subject, condition, template_freq,
%                       template_level, TEMPLATEdir)
%
%   create_abr_template(..., done_callback)
%       done_callback is an optional function handle called with no arguments
%       after the template is saved (or the user cancels). Use this to
%       refresh UI state in the calling app.
%
%   Inputs
%   ------
%   ROOTdir        - Root data directory (e.g. '/Volumes/FefeSSD/DOD')
%   subject        - Subject ID string (e.g. 'Q494')
%   condition      - Condition path relative to subject ABR folder
%                    (e.g. 'pre/Baseline')
%   template_freq  - Stimulus frequency in Hz (0 = click)
%   template_level - Stimulus level in dB SPL
%   TEMPLATEdir    - Full path to templates output folder
%   done_callback  - (optional) function handle called when finished
%
%Author: Andrew Sivaprakasam / Fernando Aguilera de Alba
%Last Updated: Apr 2026

if nargin < 7, done_callback = []; end

%% Locate data file
datapath = fullfile(ROOTdir, 'Data', subject, 'ABR', condition);
if ~exist(datapath, 'dir')
    error('create_abr_template:pathNotFound', 'Data path not found:\n%s', datapath);
end

if template_freq == 0
    datafiles = dir(fullfile(datapath, 'p*click*.mat'));
else
    datafiles = dir(fullfile(datapath, ['p*', mat2str(template_freq), '*.mat']));
end

if isempty(datafiles)
    if template_freq == 0, freq_str = 'click'; else, freq_str = [num2str(template_freq), 'Hz']; end
    error('create_abr_template:noFiles', 'No data files found for %s %d dB SPL in:\n%s', freq_str, template_level, datapath);
end

%% Find file matching the requested level
abr = []; t = []; freq_str = ''; level_spl = nan;
for d = 1:length(datafiles)
    load(fullfile(datapath, datafiles(d).name), 'x');
    lev = round(x.Stimuli.MaxdBSPLCalib - x.Stimuli.atten_dB);
    if lev == template_level
        fs = 8e3;
        if iscell(x.AD_Data.AD_All_V{1})
            abr_raw = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1}));
        else
            abr_raw = mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V)));
        end
        abr = resample(abr_raw, fs, round(x.Stimuli.RPsamprate_Hz));
        abr = abr - mean(abr);
        t   = x.Stimuli.CAP_Gating.XstartPlot_ms/1000 : 1/fs : x.Stimuli.CAP_Gating.XendPlot_ms/1000 - 1/fs;
        % trim or pad t to match abr length
        if length(t) > length(abr), t = t(1:length(abr)); end
        if length(t) < length(abr), abr = abr(1:length(t)); end
        if x.Stimuli.clickYes
            freq_str  = 'click';
            level_spl = lev;
        else
            freq_str  = [num2str(x.Stimuli.freq_hz), 'Hz'];
            level_spl = lev;
        end
        clear x;
        break;
    end
    clear x;
end

if isempty(abr)
    if template_freq == 0, fs_str = 'click'; else, fs_str = [num2str(template_freq), 'Hz']; end
    error('create_abr_template:levelNotFound', 'No file found at %d dB SPL for %s.', template_level, fs_str);
end

template_name = ['template_', freq_str, '_', mat2str(level_spl), 'dBSPL'];

%% Interactive peak picking loop
point_names = {'P1','N1','P2','N2','P3','N3','P5','N5'};
num_peaks   = length(point_names);
satisfied   = false;

while ~satisfied
    fig_h = figure(998);
    clf(fig_h);
    plot(t * 1000, abr * 1e6, 'k-', 'LineWidth', 3);   % plot in ms and µV for readability
    xlim([0, 20]);
    xlabel('Time (ms)', 'FontSize', 18);
    ylabel('Amplitude (\muV)', 'FontSize', 18);
    title(sprintf('ABR Template | %s | %d dB SPL', freq_str, level_spl), 'FontSize', 20);
    set(gca, 'FontSize', 16);
    set(fig_h, 'Position', get(0, 'Screensize'));

    points = zeros(num_peaks, 3);   % [time_s, amplitude_V, sample_index]
    for i = 1:num_peaks
        subtitle(sprintf('Click nearest point for  %s  (%d / %d)', point_names{i}, i, num_peaks), 'FontSize', 16);
        figure(fig_h);   % bring figure to front so ginput receives clicks
        drawnow;
        [x_click, ~] = ginput(1);
        x_click_s = x_click / 1000;                        % convert ms → s
        [~, idx]  = min(abs(t - x_click_s));
        x_snap    = t(idx);
        y_snap    = abr(idx);
        hold on;
        plot(x_snap * 1000, y_snap * 1e6, 'ro', 'MarkerSize', 12, 'LineWidth', 3);
        text(x_snap * 1000, y_snap * 1e6, ['  ', point_names{i}], ...
            'VerticalAlignment', 'bottom', 'FontSize', 16, 'Color', 'r');
        points(i, :) = [x_snap, y_snap, idx];
    end
    hold off;
    drawnow;

    answer = questdlg('Save this template?', 'Template Review', 'Save', 'Redo', 'Cancel', 'Save');
    switch answer
        case 'Save'
            if ~exist(TEMPLATEdir, 'dir'), mkdir(TEMPLATEdir); end
            save(fullfile(TEMPLATEdir, template_name), 'points', 't', 'abr', 'point_names');
            fprintf('[create_abr_template] Saved: %s\n', fullfile(TEMPLATEdir, template_name));
            close(fig_h);
            satisfied = true;
        case 'Redo'
            clf(fig_h);
        otherwise   % Cancel
            close(fig_h);
            satisfied = true;
    end
end

if ~isempty(done_callback) && isa(done_callback, 'function_handle')
    done_callback();
end
end
