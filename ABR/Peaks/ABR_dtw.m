function ABR_dtw(ROOTdir,CODEdir,datapaths,outpaths,Chins2Run,ChinIND,all_Conds2Run,Conds2Run,CondINDs,colors,shapes,ylimits_ind,freq,levels,template_per_level,peak_ui,wave_sel)
%Author (s): Andrew Sivaprakasam
%Last Updated: 14 Apr 2026
%Description: Script to process ABR waveforms to automatically select peaks
%using Dynamic Time Warping (DTW).
%
%  datapaths  – cell array of raw data paths, one per condition
%  outpaths   – cell array of output paths, one per condition
%  CondINDs   – integer array of condition indices (into all_Conds2Run)
%
%  Loop order: frequency → condition → level
%  This ensures all conditions for a given frequency are processed together,
%  so the waterfall accumulates across conditions before moving to the next freq.

template_shift = 'none';        % xcorr / peak / none
if ~exist('template_per_level','var') || isempty(template_per_level), template_per_level = false; end
if ~exist('peak_ui','var'), peak_ui  = []; end
if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
cwd = pwd;
TEMPLATEdir = strcat(CODEdir,filesep,'templates');

%% Find the level (dB SPL) of every ABR file (per condition, per frequency)
% Each file is read once. The file list/order must match the glob used
% when the waveform is loaded below, so indices stay consistent.
file_lev = cell(numel(CondINDs), length(freq));
for ci = 1:numel(CondINDs)
    cd(datapaths{ci});
    for z = 1:length(freq)
        if freq(z) == 0
            datafiles = {dir(fullfile(cd,'p*click*.mat')).name};
        else
            datafiles = {dir(fullfile(cd,['p*',mat2str(freq(z)),'*.mat'])).name};
        end
        levs = nan(1, numel(datafiles));
        for i = 1:numel(datafiles)
            if strncmp(datafiles{i}, '._', 2), continue; end   % macOS resource fork
            try
                S = load(fullfile(datapaths{ci}, datafiles{i}), 'x');
                levs(i) = round(S.x.Stimuli.MaxdBSPLCalib - S.x.Stimuli.atten_dB);
            catch ME
                fprintf('  [ABR_dtw] Could not read level from %s: %s\n', datafiles{i}, ME.message);
            end
        end
        file_lev{ci,z} = levs;
    end
end

% Levels to analyse: every level present in the data (highest → lowest),
% unless the caller passed an explicit list.
if isempty(levels)
    all_levs = [file_lev{:}];
    levels   = sort(unique(all_levs(~isnan(all_levs))), 'descend');
    fprintf('  [ABR_dtw] Levels found: %s dB SPL\n', mat2str(levels));
end
levels = levels(:)';

idx_abr = cell(1, numel(CondINDs));
for ci = 1:numel(CondINDs)
    idx_abr{ci} = nan(length(levels),length(freq));
    for z = 1:length(freq)
        for j = 1:length(levels)
            i = find(file_lev{ci,z} == levels(j), 1, 'last');
            if ~isempty(i), idx_abr{ci}(j,z) = i; end
        end
    end
end

%% Check all templates available
% tpl_levels{z}: every template level that exists for frequency z, used to
% pick the NEAREST template when a recorded level has no exact template
% (e.g. 90 dB → 80 dB template, 20 dB → 30 dB template).
tpl_levels = cell(1, length(freq));
for z = 1:length(freq)
    if freq(z) == 0, fs_ = 'click'; else, fs_ = [num2str(freq(z)),'Hz']; end
    tf = dir(fullfile(TEMPLATEdir, sprintf('template_%s_*dBSPL.mat', fs_)));
    tf = tf(~strncmp({tf.name},'._',2));
    tok = regexp({tf.name}, '_(-?\d+)dBSPL\.mat$', 'tokens', 'once');
    tok = tok(~cellfun(@isempty, tok));
    tpl_levels{z} = sort(cellfun(@(t) str2double(t{1}), tok));
end
idx_template = nan(length(levels),length(freq));
for z = 1:length(freq)
    for j = 1:length(levels)
        if freq(z) == 0, freq_str = 'click'; else, freq_str = [num2str(freq(z)),'Hz']; end
        cd(TEMPLATEdir)
        template_str = dir(sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(j))));
        if ~isempty(template_str)
            idx_template(j,z) = 1;
        end
    end
end
fprintf('\n\nTemplate Availability\n\n');
fprintf('%-10s', 'dB SPL');
fprintf('\n');
for i = 1:size(levels,2)
    fprintf('%-10s', mat2str(levels(i)));
    for j = 1:size(idx_template,2)
        if ~isnan(idx_template(i,j))
            fprintf('%-10s', 'YES');
        else
            fprintf('%-10s', 'NO');
        end
    end
    fprintf('\n');
end

%% Dynamic Time Warping: freq-outer, condition-inner, level-innermost
all_point_names = {'P1','N1','P2','N2','P3','N3','P4','N4','P5','N5'};

for z = 1:length(freq)
    if freq(z) == 0, freq_str = 'click'; else, freq_str = [num2str(freq(z)),'Hz']; end

    for ci = 1:numel(CondINDs)
        CondIND   = CondINDs(ci);
        datapath  = datapaths{ci};
        outpath   = outpaths{ci};
        if isstruct(peak_ui) && isfield(peak_ui,'blind') && peak_ui.blind
            peak_ui.blind_cond = sprintf('%d / %d', ci, numel(CondINDs));   % order is randomised upstream
        end
        condition = strsplit(all_Conds2Run{CondIND}, filesep);
        n_lev     = length(levels);

        abr_points = nan(length(all_point_names),3);
        abrs = struct();
        abrs.nel = []; abrs.subject = []; abrs.sex = [];

        % ── 1) Load every level first (template + waveform) ────────────────
        % so the whole waterfall can be shown up front and any level can be
        % revisited in any order.
        L = repmat(struct('t',[],'data',[],'tpl',nan,'pts',nan(10,3)), 1, n_lev);
        has_data = false(1, n_lev);
        for j = 1:n_lev
            if isnan(idx_abr{ci}(j,z)), continue; end   % level not recorded
                % Determine template
                if ~isnan(idx_template(j,z))
                    template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(j)));
                elseif ~template_per_level && ~isempty(tpl_levels{z})
                    % No exact template: use the closest template level
                    [~, ii]   = min(abs(tpl_levels{z} - levels(j)));
                    tpl_lev   = tpl_levels{z}(ii);
                    template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(tpl_lev));
                    fprintf('  [ABR_dtw] Using %d dB template (nearest) for %s %d dB SPL.\n', tpl_lev, freq_str, levels(j));
                else
                    template_filename = '';
                end
                % Load template (guard against missing file)
                if ~isempty(template_filename) && exist(fullfile(TEMPLATEdir,template_filename),'file')
                    cd(TEMPLATEdir);
                    load(template_filename)
                    abr_template = abr - mean(abr);
                    idx_abr_points = ismember(all_point_names,point_names);
                    abr_points(idx_abr_points,:) = points;
                else
                    if ~isempty(template_filename)
                        fprintf('  [ABR_dtw] Template not found: %s — running without template.\n', template_filename);
                    else
                        fprintf('  [ABR_dtw] No template for %s %d dB SPL — running without template.\n', freq_str, levels(j));
                    end
                    abr_template = nan(1,1);
                    abr_points   = nan(10,3);
                end
                % Load ABR file
                cd(datapath);
                if freq(z) == 0
                    datafiles = {dir(fullfile(cd,'p*click*.mat')).name};
                else
                    datafiles = {dir(fullfile(cd,['p*',mat2str(freq(z)),'*.mat'])).name};
                end
                load(datafiles{idx_abr{ci}(j,z)});
                % Resample and remove DC
                fs = 8e3;
                if iscell(x.AD_Data.AD_All_V{1})
                    abr_data = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1}));
                else
                    abr_data = mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V)));
                end
                abr_data = resample(abr_data,fs,round(x.Stimuli.RPsamprate_Hz));
                abr_t = (1:length(abr_data))/fs;

                % MetaData (NEL / sex from the acquisition file, if recorded)
                if isfield(x,'MetaData') && ~isempty(x.MetaData)
                    md = x.MetaData;
                    if isfield(md,'NEL') && ~isempty(md.NEL) && isempty(abrs.nel)
                        abrs.nel = str2double(md.NEL(end));
                    end
                    if isfield(md,'Sex') && ~isempty(md.Sex) && isempty(abrs.sex)
                        abrs.sex = upper(char(md.Sex(1)));
                    end
                    if isfield(md,'ChinID') && ~isempty(md.ChinID)
                        abrs.subject_metadata = md.ChinID;
                    end
                end

                % Shift template to better match ABR waveform
                switch template_shift
                    case 'xcorr'
                        [xcorr_out, lags] = xcorr(abr_data/(max(abr_data)-min(abr_data)), abr_template/(max(abr_template)-min(abr_template)), 'coeff');
                        [~, max_idx] = max(xcorr_out);
                        sample_diff = lags(max_idx);
                    case 'peak'
                        minPeakDistance = round(0.001 * fs);
                        abr_prom_thresh      = median(abs(abr_data/(max(abr_data)-min(abr_data))));
                        template_prom_thresh = median(abs(abr_template/(max(abr_template)-min(abr_template))));
                        [~, locs_abr]      = findpeaks(abr_data/(max(abr_data)-min(abr_data)),'MinPeakProminence',abr_prom_thresh,'MinPeakDistance',minPeakDistance);
                        [~, locs_template] = findpeaks(abr_template/(max(abr_template)-min(abr_template)),'MinPeakProminence',template_prom_thresh,'MinPeakDistance',minPeakDistance);
                        sample_diff = locs_abr(1) - locs_template(1);
                    case 'none'
                        sample_diff = 0;
                end

                % Apply shift
                if sample_diff > 0      % ABR leading
                    temp = abr_template(1:abs(sample_diff));
                    template_temp = [temp,temp,abr_template(abs(sample_diff)+1:end-abs(sample_diff))];
                    abr_template = template_temp;
                    abr_points(:,1) = abr_points(:,1) + sample_diff/fs;
                    abr_points(:,3) = abr_points(:,3) + sample_diff;
                elseif sample_diff < 0   % template leading
                    temp = abr_template(end-abs(sample_diff)+1:end);
                    template_temp = [abr_template(abs(sample_diff)+1:end-abs(sample_diff)),temp,temp];
                    abr_template = template_temp;
                    abr_points(:,1) = abr_points(:,1) - sample_diff/fs;
                    abr_points(:,3) = abr_points(:,3) - sample_diff;
                end

                L(j).t    = abr_t;
                L(j).data = abr_data;
                L(j).tpl  = abr_template;
                L(j).pts  = abr_points;
                has_data(j) = true;
        end

        % ── 2) Peak picking ─────────────────────────────────────────────────
        fig_num = (ChinIND-1)*length(freq)*numel(CondINDs) + (z-1)*numel(CondINDs) + ci;
        PA = nan(n_lev, numel(all_point_names));     % peak amplitudes
        PL = nan(n_lev, numel(all_point_names));     % peak latencies
        use_session = isstruct(peak_ui) && isfield(peak_ui,'fig') && isvalid(peak_ui.fig);
        vis_thr = NaN;  vis_src = '';                  % visual threshold (app mode)
        save_mode = 'overwrite';                       % or 'new' (keep the existing file)
        if use_session
            % App mode: full waterfall on the left; levels are proposed high →
            % low, but clicking any level in the waterfall jumps to it.
            if isfield(peak_ui,'blind') && peak_ui.blind
                wf_clr = [0.25 0.25 0.25];
            else
                wf_clr = colors(CondIND,:);
            end
            S = wf_begin(peak_ui, sprintf('%s|%s', Chins2Run{ChinIND}, freq_str), ...
                         levels, L, has_data, wf_clr);
            visited    = false(1, n_lev);
            inds_store = cell(1, n_lev);
            % Pre-compute the automatic picks of every level. Markers appear
            % on the waterfall only once a level has been opened in the editor.
            PKs = cell(1, n_lev);  LATs = cell(1, n_lev);
            for jj = find(has_data)
                [pk, lat, inds] = findPeaks_dtw(L(jj).t, L(jj).data, L(jj).tpl, L(jj).pts, ...
                    Chins2Run(ChinIND), condition{2}, Conds2Run, CondIND, ChinIND, levels, fig_num, jj, ...
                    colors, shapes, ylimits_ind, freq_str, idx_abr{ci}(jj,z), idx_template(jj,z), ...
                    outpath, peak_ui, wave_sel, struct('session',true,'auto_only',true,'do_log',false));
                inds_store{jj} = inds;
                PKs{jj} = pk;  LATs{jj} = lat;
            end
            % ── Re-analysis: preload the existing peaks file for this freq ──
            prev = [];
            prev_file = fullfile(outpath, [cell2mat([Chins2Run(ChinIND),'_',condition{2}, ...
                                 '_ABRpeaks_dtw_',freq_str]) '.mat']);
            if exist(prev_file, 'file')
                try
                    tmp_prev = load(prev_file, 'abrs');  prev = tmp_prev.abrs;
                catch
                    prev = [];
                end
            end
            if isstruct(prev) && isfield(prev,'peak_latency') && isfield(prev,'levels')
                for jj = find(has_data)
                    k = find(round(prev.levels(:)) == round(levels(jj)), 1);
                    if isempty(k) || size(prev.peak_latency,1) < k, continue; end
                    lat_ms = prev.peak_latency(k,:);
                    if all(abs(lat_ms(isfinite(lat_ms))) < 0.1), lat_ms = lat_ms*1e3; end  % old files in s
                    idx = round(lat_ms * 8);                        % t = (1:n)/8 kHz → ms
                    idx(idx < 1 | idx > numel(L(jj).data)) = NaN;
                    init = nan(1, numel(inds_store{jj}));
                    m = min(numel(init), numel(idx));
                    init(1:m) = idx(1:m);
                    inds_store{jj} = init;
                    s_uv = L(jj).data * 1e2;  pk = nan(size(init));
                    pk(~isnan(init)) = s_uv(init(~isnan(init)));
                    PKs{jj} = pk;  LATs{jj} = init / 8;
                end
                if isfield(prev,'threshold_visual') && isfinite(prev.threshold_visual)
                    src = 'manual';
                    if isfield(prev,'threshold_visual_source') && ~isempty(prev.threshold_visual_source)
                        src = prev.threshold_visual_source;
                    end
                    S = wf_relayout(S, prev.threshold_visual, src, colors, shapes, wave_sel);
                end
                peak_ui_msg(peak_ui, 'Loaded existing peaks for re-analysis');
            end

            % ── NEL / sex prefill. NEL: existing file → acquisition metadata.
            %    Sex: chinroster → existing file → metadata → earlier condition
            %    of the same subject in this run. The user can change both.
            nel0 = abrs.nel;  sex0 = abrs.sex;
            if isstruct(prev)
                if isfield(prev,'nel') && ~isempty(prev.nel) && isfinite(prev.nel), nel0 = prev.nel; end
                if isfield(prev,'sex') && ~isempty(prev.sex), sex0 = prev.sex; end
            end
            % Sex from the chinroster "Sex" column takes priority
            if isfield(peak_ui,'sex_ids') && ~isempty(peak_ui.sex_ids)
                ks = find(strcmp(peak_ui.sex_ids, Chins2Run{ChinIND}), 1);
                if ~isempty(ks) && ~isempty(peak_ui.sex_vals{ks}), sex0 = peak_ui.sex_vals{ks}; end
            end
            subj_sex = getappdata(peak_ui.fig, 'peak_subj_sex');
            if isempty(sex0) && isstruct(subj_sex) && isfield(subj_sex,'id') && strcmp(subj_sex.id, Chins2Run{ChinIND})
                sex0 = subj_sex.sex;
            end
            meta_init(peak_ui, nel0, sex0);

            % Edit loop: start at the highest level; the user moves between
            % levels by clicking the waterfall (or ↑/↓), can set the visual
            % threshold, and presses "Done" once the waterfall is finished.
            % Levels below the threshold can still be opened and edited, but
            % their waves are hidden on the waterfall and saved as NaN; the
            % picks are kept, so lowering the threshold brings them back.
            peak_ui.fig.WindowKeyPressFcn = @(src,ev) wf_key(src, ev);
            j = find(S.has_data, 1);
            while ~isempty(j)
                setappdata(peak_ui.fig, 'peak_wf_cur', j);
                S = wf_set_current(S, j, visited);
                S = wf_update_level(S, j, PKs{j}, LATs{j}, colors, shapes, wave_sel);  % show this level's picks
                opts = struct('session',true, 'init_inds',inds_store{j}, 'do_log',false);
                [pk, lat, inds, nav] = findPeaks_dtw(L(j).t, L(j).data, L(j).tpl, L(j).pts, ...
                    Chins2Run(ChinIND), condition{2}, Conds2Run, CondIND, ChinIND, levels, fig_num, j, ...
                    colors, shapes, ylimits_ind, freq_str, idx_abr{ci}(j,z), idx_template(j,z), ...
                    outpath, peak_ui, wave_sel, opts);
                if ~isvalid(peak_ui.fig), break; end           % app closed mid-session
                inds_store{j} = inds;
                PKs{j} = pk;  LATs{j} = lat;
                visited(j)    = true;
                S = wf_update_level(S, j, pk, lat, colors, shapes, wave_sel);
                if strcmp(nav.type,'thresh') && ~isempty(nav.level)
                    % Visual threshold set on the waterfall → re-space levels
                    S = wf_relayout(S, levels(nav.level), 'manual', colors, shapes, wave_sel);
                    peak_ui_msg(peak_ui, sprintf('Threshold set to %d dB SPL', levels(nav.level)));
                elseif strcmp(nav.type,'goto') && ~isempty(nav.level) && S.has_data(nav.level)
                    j = nav.level;                              % switch level (any recorded level)
                    peak_ui_msg(peak_ui, 'Loading level…');
                elseif strcmp(nav.type,'goto')
                    % clicked an unrecorded level: stay on this level
                else
                    % "Done": confirm NEL / sex, and overwrite vs. new file
                    [ok_done, save_mode] = confirm_done(peak_ui, isstruct(prev));
                    if ok_done, j = []; end                    % else keep editing this level
                end
            end
            % Finalise every level from its latest picks (and log them once).
            % Levels below the visual threshold get no peaks (NaN).
            if isvalid(peak_ui.fig)
                peak_ui.fig.WindowKeyPressFcn = '';
                peak_ui_msg(peak_ui, 'Saving peaks…');
                for jj = find(S.pickable)
                    [pk, lat] = findPeaks_dtw(L(jj).t, L(jj).data, L(jj).tpl, L(jj).pts, ...
                        Chins2Run(ChinIND), condition{2}, Conds2Run, CondIND, ChinIND, levels, fig_num, jj, ...
                        colors, shapes, ylimits_ind, freq_str, idx_abr{ci}(jj,z), idx_template(jj,z), ...
                        outpath, peak_ui, wave_sel, ...
                        struct('session',true,'auto_only',true,'init_inds',inds_store{jj},'do_log',true));
                    PA(jj,:) = pad_row(pk, size(PA,2));
                    PL(jj,:) = pad_row(lat, size(PL,2));
                end
                wf_set_current(S, [], true(1, n_lev));
            end
            vis_thr = S.thr;  vis_src = S.thr_src;
            [abrs.nel, abrs.sex] = meta_read(peak_ui);
            abrs.nel_sex_confirmed = ~isnan(abrs.nel) && ~isempty(abrs.sex);
            if ~isempty(abrs.sex)
                setappdata(peak_ui.fig, 'peak_subj_sex', struct('id',Chins2Run{ChinIND}, 'sex',abrs.sex));
            end
            peak_ui_inter_busy(peak_ui, n_lev, n_lev, ci, numel(CondINDs), z, length(freq));
        else
            % Classic (standalone) mode: one level at a time, high → low
            for j = 1:n_lev
                if ~has_data(j), continue; end
                [pk, lat] = findPeaks_dtw(L(j).t, L(j).data, L(j).tpl, L(j).pts, ...
                    Chins2Run(ChinIND), condition{2}, Conds2Run, CondIND, ChinIND, levels, fig_num, j, ...
                    colors, shapes, ylimits_ind, freq_str, idx_abr{ci}(j,z), idx_template(j,z), ...
                    outpath, peak_ui, wave_sel);
                PA(j,:) = pad_row(pk, size(PA,2));
                PL(j,:) = pad_row(lat, size(PL,2));
            end
        end

        % ── 3) Assemble output (unrecorded levels stay NaN) ─────────────────
        abrs.subject        = Chins2Run{ChinIND};   % roster ID (always saved)
        abrs.levels         = levels';
        abrs.threshold_visual        = vis_thr;   % dB SPL; levels below have no peaks (NaN)
        abrs.threshold_visual_source = vis_src;   % 'auto' (estimate accepted) or 'manual'
        abrs.peak_amplitude = PA;
        abrs.peak_latency   = PL;
        avail = find(has_data);
        if ~isempty(avail)
            ns = max(arrayfun(@(k) numel(L(k).data), avail));
            W  = nan(n_lev, ns);
            for k = avail, W(k, 1:numel(L(k).data)) = L(k).data * 10^2; end
            abrs.freq           = freq(z);
            abrs.waveforms      = W;
            abrs.waveforms_time = (1:ns) / 8e3 * 10^3;
        else
            abrs.freq = [];  abrs.waveforms = [];  abrs.waveforms_time = [];
        end

        %% Export per (condition, freq)
        cd(outpath);
        filename = cell2mat([Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_',freq_str]);
        if strcmp(save_mode, 'new')
            % Keep the existing file; save this analysis as the next version
            v = 2;
            while exist(fullfile(outpath, sprintf('%s_v%d.mat', filename, v)), 'file'), v = v + 1; end
            filename = sprintf('%s_v%d', filename, v);
        end
        % Save waterfall figure
        wf_name = sprintf('Peaks Waterfall|%s|%s', condition{end}, freq_str);
        fh = findobj('Type','figure','Name',wf_name);
        if ~isempty(fh) && isvalid(fh(1))
            print(fh(1),[filename,'_figure'],'-dpng','-r300');
        end
        % Close classic interactive edit figure (standalone mode only)
        if isempty(peak_ui)
            fedit = findobj('Type','figure','Name','ABR Peak Selection');
            if ~isempty(fedit), close(fedit); end
        end
        save(filename,'abrs')
        cd(cwd)
    end
end
end


function peak_ui_inter_busy(peak_ui, j, n_levels, ci, n_conds, z, n_freqs)
%PEAK_UI_INTER_BUSY  Show a contextual loading message between findPeaks_dtw
%   calls so the user knows the app is busy loading the next waveform.
if isempty(peak_ui) || ~isstruct(peak_ui) || ~isvalid(peak_ui.fig), return; end
if j < n_levels
    msg = sprintf('Loading level %d / %d…', j+1, n_levels);
elseif ci < n_conds
    msg = sprintf('Loading condition %d / %d…', ci+1, n_conds);
elseif z < n_freqs
    msg = sprintf('Loading frequency %d / %d…', z+1, n_freqs);
else
    msg = 'Finishing up…';
end
peak_ui.status_lbl.Text      = msg;
peak_ui.status_lbl.FontColor = [0.72 0.35 0.00];
peak_ui.done_btn.Enable      = 'off';
peak_ui.accept_btn.Enable    = 'off';
peak_ui.redo_btn.Enable      = 'off';
peak_ui.cancel_btn.Enable    = 'off';
drawnow;
end


function r = pad_row(v, n)
%PAD_ROW  Return v as a 1×n row (NaN-padded / truncated).
r = nan(1, n);
v = v(:)';
m = min(n, numel(v));
r(1:m) = v(1:m);
end


function peak_ui_msg(peak_ui, msg)
if isempty(peak_ui) || ~isstruct(peak_ui) || ~isvalid(peak_ui.fig), return; end
peak_ui.status_lbl.Text      = msg;
peak_ui.status_lbl.FontColor = [0.72 0.35 0.00];
drawnow limitrate;
end


% ══════════════════════════════════════════════════════════════════════════
%  Interactive waterfall (app mode): all levels shown, click a level to edit
%  it; levels below the visual threshold are squeezed together and not picked
% ══════════════════════════════════════════════════════════════════════════

function S = wf_begin(peak_ui, ~, levels, L, has_data, wf_clr)
%WF_BEGIN  Build the waterfall for one condition: every level, an automatic
%   threshold estimate (the user can change it), threshold-aware spacing.
fig = peak_ui.fig;
ax  = getappdata(fig, 'peak_wf_ax');
if isempty(ax) || ~isvalid(ax), ax = peak_ui.wf_ax; end
n   = numel(levels);
S   = struct();
S.levels = levels(:)';  S.has_data = has_data;  S.wf_clr = wf_clr;
S.sig = cell(1,n);  S.t = cell(1,n);  S.mu = nan(1,n);  S.rng = nan(1,n);
for j = find(has_data)
    s = L(j).data * 1e2;
    S.mu(j)  = mean(s);
    S.sig{j} = s - S.mu(j);
    S.t{j}   = L(j).t * 1e3;
    S.rng(j) = max(S.sig{j}) - min(S.sig{j});
end
S.pk = cell(1,n);  S.lat = cell(1,n);  S.shown = false(1,n);
S.colors = [];  S.shapes = '';  S.wave_sel = true(1,5);

% Fresh axes for every condition (each condition has its own threshold)
parent = ax.Parent;  pos = ax.Position;  un = ax.Units;
delete(ax);
ax = uiaxes(parent, 'Units', un, 'Position', pos);
disableDefaultInteractivity(ax);
setappdata(fig, 'peak_wf_ax', ax);
hold(ax,'on');  grid(ax,'on');
xlabel(ax, 'Time (ms)', 'FontWeight','bold', 'FontSize',15);
set(ax, 'YColor','none', 'FontSize',13);
xlim(ax, [0 20]);
title(ax, 'Click any level to edit it', 'FontSize',12, 'FontWeight','normal', ...
    'Color',[0.45 0.45 0.45]);
S.ax = ax;

% Graphics (positions are set by wf_relayout)
S.h_band = patch(ax, [0 20 20 0], [0 0 1 1], [0.81 0.73 0.57], ...
    'FaceAlpha',0.25, 'EdgeColor','none', 'Visible','off');
S.h_tr  = gobjects(1,n);
S.h_lbl = gobjects(1,n);
for j = 1:n
    S.h_lbl(j) = text(ax, 0.3, 0, sprintf('%d dB', levels(j)), ...
        'FontSize',13, 'FontWeight','bold', 'VerticalAlignment','middle');
    if has_data(j)
        S.h_tr(j) = plot(ax, S.t{j}, S.sig{j}, 'Color',[0.72 0.72 0.72], 'LineWidth',1.2);
    end
end
S.h_sb   = plot(ax, [18.8 18.8], [0 1], 'k-', 'LineWidth',2.5);
S.h_sbT  = text(ax, 18.65, 0.5, '1 \muV', 'FontSize',11, 'FontWeight','bold', ...
    'HorizontalAlignment','right', 'VerticalAlignment','middle');
S.h_mk = cell(1,n);
S.cur  = [];

% Clicks: every child ignores them so they reach the axes
set(ax.Children, 'HitTest','off', 'PickableParts','none');
set(ax, 'HitTest','on', 'PickableParts','all');
ax.ButtonDownFcn = @(src,~) wf_click(fig, src);
if isfield(peak_ui,'thresh_btn') && isvalid(peak_ui.thresh_btn)
    % "Set as Threshold" → the level currently in the editor
    peak_ui.thresh_btn.ButtonPushedFcn = @(~,~) wf_thresh_current(fig);
    peak_ui.thresh_btn.Visible = 'on';
end

S = wf_relayout(S, wf_auto_threshold(S), 'auto', [], '', []);
uistack(S.h_band, 'bottom');
drawnow;
end


function thr = wf_auto_threshold(S)
%WF_AUTO_THRESHOLD  First guess at the visual threshold: the lowest level of
%   the uninterrupted run (from the top) whose response window (5–12 ms) is
%   clearly larger than the pre-response noise (0–4 ms).
idx = find(S.has_data);
snr = nan(1, numel(S.levels));
for j = idx
    t = S.t{j};  s = S.sig{j};
    resp  = s(t >= 5 & t <= 12);
    noise = s(t >= 0.5 & t <= 4);
    if isempty(resp) || isempty(noise), continue; end
    snr(j) = std(resp) / max(std(noise), eps);
end
thr = NaN;
for j = idx                                   % high → low
    if snr(j) >= 2, thr = S.levels(j); else, break; end
end
if isnan(thr), thr = min(S.levels(idx)); end  % no clear response: keep all pickable
end


function S = wf_relayout(S, thr, src, colors, shapes, wave_sel)
%WF_RELAYOUT  Set the visual threshold and re-space the waterfall: levels at
%   or above threshold get full spacing; levels below are squeezed together.
if ~isempty(colors), S.colors = colors; S.shapes = shapes; S.wave_sel = wave_sel; end
S.thr = thr;  S.thr_src = src;
n   = numel(S.levels);
above = S.levels >= thr;
S.pickable = S.has_data & above;
r_hi = S.rng(S.has_data & above);   if isempty(r_hi), r_hi = S.rng(S.has_data); end
r_lo = S.rng(S.has_data & ~above);
vsp_hi = max([0.6*max(r_hi), 1.15*median(r_hi), 0.2]);
if isempty(r_lo)
    vsp_lo = vsp_hi;
else
    vsp_lo = min(0.45*vsp_hi, max(1.1*median(r_lo), 0.2*vsp_hi));
end
% Offsets (top level at 0) and the gap above each level
gap = zeros(1,n);  off = zeros(1,n);
for j = 2:n
    if above(j),         gap(j) = vsp_hi;
    elseif above(j-1),   gap(j) = (vsp_hi + vsp_lo)/2;   % first level below threshold
    else,                gap(j) = vsp_lo;
    end
    off(j) = off(j-1) - gap(j);
end
gap(1) = vsp_hi;
S.off = off;  S.gap = gap;  S.vsp_hi = vsp_hi;
setappdata(ancestor(S.ax,'figure'), 'peak_wf_off', off);
setappdata(ancestor(S.ax,'figure'), 'peak_wf_pickable', S.has_data);   % any recorded level can be opened

% Traces + labels (the threshold level's label is red and tagged)
if strcmp(src,'auto'), tag = 'threshold (auto)'; else, tag = 'threshold'; end
for j = 1:n
    if S.levels(j) == thr
        S.h_lbl(j).String = {sprintf('%d dB', S.levels(j)), tag};   % "threshold" on the line below
    else
        S.h_lbl(j).String = sprintf('%d dB', S.levels(j));
    end
    lbl_gap = gap(j);  if j == 1, lbl_gap = vsp_hi; end
    if above(j)
        set(S.h_lbl(j), 'Position',[0.3, off(j) + 0.42*min(lbl_gap, vsp_hi), 0], ...
            'FontSize',13, 'Color',[0 0 0]);
    else
        set(S.h_lbl(j), 'Position',[0.3, off(j) + 0.45*lbl_gap, 0], ...
            'FontSize',10, 'Color',[0.55 0.55 0.55]);
    end
    if isgraphics(S.h_tr(j)), S.h_tr(j).YData = S.sig{j} + off(j); end
end
k_thr = find(S.levels == thr, 1);
if ~isempty(k_thr), S.h_lbl(k_thr).Color = [0.80 0.15 0.15]; end


% Markers: hide levels below threshold, redraw the rest at new offsets
for j = 1:n
    if S.shown(j) && S.pickable(j) && ~isempty(S.colors)
        S = wf_update_level(S, j, S.pk{j}, S.lat{j}, S.colors, S.shapes, S.wave_sel);
    elseif ~isempty(S.h_mk{j})
        delete(S.h_mk{j}(isgraphics(S.h_mk{j})));  S.h_mk{j} = gobjects(0);
    end
end

% Scale bar on the bottom trace; y-limits fitted so nothing is clipped
set(S.h_sb, 'YData',[off(1) off(1)+1]);              % scale bar on the highest level
set(S.h_sbT, 'Position',[18.65, off(1)+0.5, 0]);
top = 0.5*vsp_hi;  bot = off(end) - vsp_lo;
for j = find(S.has_data)
    top = max(top, max(S.sig{j}) + off(j));
    bot = min(bot, min(S.sig{j}) + off(j));
end
pad = 0.04 * (top - bot);
ylim(S.ax, [bot - pad, top + pad + 0.3*vsp_hi]);   % headroom for the top level's label
if ~isempty(S.cur), S = wf_set_current(S, S.cur, S.shown); end
drawnow limitrate;
end


function S = wf_set_current(S, j, done)
%WF_SET_CURRENT  Highlight level j (gold band, dark trace); picked levels in
%   the condition colour, pending levels light grey.
if ~isgraphics(S.ax), return; end
S.cur = j;
for k = find(isgraphics(S.h_tr))
    if ~isempty(j) && k == j
        set(S.h_tr(k), 'Color',[0.08 0.08 0.08], 'LineWidth',2.0);
    elseif done(k) && S.pickable(k)
        set(S.h_tr(k), 'Color',S.wf_clr, 'LineWidth',1.5);
    else
        set(S.h_tr(k), 'Color',[0.72 0.72 0.72], 'LineWidth',1.2);
    end
end
if isempty(j)
    S.h_band.Visible = 'off';
else
    h_up = S.gap(j);  if j == 1, h_up = S.vsp_hi; end
    if j < numel(S.off), h_dn = S.gap(j+1); else, h_dn = h_up; end
    S.h_band.YData   = S.off(j) + [-h_dn/2 -h_dn/2 h_up/2 h_up/2];
    S.h_band.Visible = 'on';
end
drawnow limitrate;
end


function S = wf_update_level(S, j, pk, lat, colors, shapes, wave_sel)
%WF_UPDATE_LEVEL  Replace level j's markers (filled = peak, hollow = trough).
if ~isgraphics(S.ax), return; end
S.pk{j} = pk;  S.lat{j} = lat;  S.shown(j) = true;
if isempty(S.colors), S.colors = colors; S.shapes = shapes; S.wave_sel = wave_sel; end
old = S.h_mk{j};
if ~isempty(old), delete(old(isgraphics(old))); end
h   = gobjects(0);
if ~S.pickable(j), S.h_mk{j} = h; return; end      % below threshold: no peaks
off = S.off(j) - S.mu(j);
for k = 1:min(5, numel(wave_sel))
    if ~wave_sel(k), continue; end
    pr = [2*k-1, 2*k];
    if numel(pk) < pr(2) || any(isnan(pk(pr))) || any(isnan(lat(pr))), continue; end
    h(end+1) = plot(S.ax, lat(pr(1)), pk(pr(1)) + off, shapes(k), ...
        'Color',colors(k+4,:), 'MarkerFaceColor',colors(k+4,:), ...
        'MarkerSize',8, 'LineWidth',1.5);                    %#ok<AGROW>
    h(end+1) = plot(S.ax, lat(pr(2)), pk(pr(2)) + off, shapes(k), ...
        'Color',colors(k+4,:), 'MarkerFaceColor','none', ...
        'MarkerSize',9, 'LineWidth',2);                      %#ok<AGROW>
end
if ~isempty(h), set(h, 'HitTest','off', 'PickableParts','none'); end
S.h_mk{j} = h;
drawnow limitrate;
end


function wf_thresh_current(fig)
%WF_THRESH_CURRENT  "Set as Threshold": the level in the editor becomes the
%   visual threshold.
cur = getappdata(fig, 'peak_wf_cur');
if isempty(cur), return; end
setappdata(fig, 'peak_action', struct('type','thresh','x',cur));
uiresume(fig);
end


function wf_click(fig, ax)
%WF_CLICK  Map a click on the waterfall to the nearest level and jump the
%   editor there (any recorded level, including below threshold).
off = getappdata(fig, 'peak_wf_off');
if isempty(off), return; end
y = ax.CurrentPoint(1,2);
[~, k] = min(abs(off - y));
pick = getappdata(fig, 'peak_wf_pickable');
if ~isempty(pick) && ~pick(k), return; end
setappdata(fig, 'peak_action', struct('type','goto','x',k));
uiresume(fig);
end


function wf_key(fig, ev)
%WF_KEY  ↑ / ↓ move to the previous / next recorded level.
pick = getappdata(fig, 'peak_wf_pickable');
cur  = getappdata(fig, 'peak_wf_cur');
if isempty(pick) || isempty(cur), return; end
switch ev.Key
    case 'downarrow', k = find(pick & (1:numel(pick)) > cur, 1, 'first');
    case 'uparrow',   k = find(pick & (1:numel(pick)) < cur, 1, 'last');
    otherwise, return;
end
if isempty(k), return; end
setappdata(fig, 'peak_action', struct('type','goto','x',k));
uiresume(fig);
end


% ══════════════════════════════════════════════════════════════════════════
%  NEL / sex confirmation and "Done" checks (app mode)
% ══════════════════════════════════════════════════════════════════════════

function meta_init(peak_ui, nel0, sex0)
%META_INIT  Prefill the NEL / Sex dropdowns; '?' = not confirmed (amber).
if ~isfield(peak_ui,'nel_dd') || ~isvalid(peak_ui.nel_dd), return; end
v = '?';
if ~isempty(nel0) && isnumeric(nel0) && isfinite(nel0) && ismember(nel0,[1 2]), v = num2str(nel0); end
peak_ui.nel_dd.Value = v;
v = '?';
if ~isempty(sex0)
    c = upper(char(sex0));  c = c(1);
    if ismember(c, {'M','F'}), v = c; end
end
peak_ui.sex_dd.Value = v;
cb = @(dd,~) meta_style(dd);
peak_ui.nel_dd.ValueChangedFcn = cb;   peak_ui.sex_dd.ValueChangedFcn = cb;
meta_style(peak_ui.nel_dd);  meta_style(peak_ui.sex_dd);
peak_ui.nel_dd.Visible = 'on';  peak_ui.sex_dd.Visible = 'on';
set(findall(peak_ui.fig,'Tag','peak_meta_lbl'), 'Visible','on');
end


function meta_style(dd)
%META_STYLE  Amber while unconfirmed ('?'), green once set.
if strcmp(dd.Value, '?')
    dd.BackgroundColor = [1.00 0.86 0.60];
else
    dd.BackgroundColor = [0.75 0.90 0.75];
end
end


function [nel, sex] = meta_read(peak_ui)
nel = NaN;  sex = '';
if ~isfield(peak_ui,'nel_dd') || ~isvalid(peak_ui.nel_dd), return; end
if ~strcmp(peak_ui.nel_dd.Value,'?'), nel = str2double(peak_ui.nel_dd.Value); end
if ~strcmp(peak_ui.sex_dd.Value,'?'), sex = peak_ui.sex_dd.Value; end
end


function [ok, save_mode] = confirm_done(peak_ui, has_prev)
%CONFIRM_DONE  Before finishing a waterfall (re-analysis only): ask whether
%   to overwrite the existing peaks file or save a new version next to it.
ok = true;  save_mode = 'overwrite';
fig = peak_ui.fig;
if has_prev
    sel = uiconfirm(fig, ['A peaks file already exists for this recording and frequency. ' ...
        'Overwrite it, or keep it and save this analysis as a new version?'], ...
        'Existing peaks file', 'Options',{'Overwrite','Save as new','Keep editing'}, ...
        'DefaultOption',1, 'CancelOption',3, 'Icon','question');
    switch sel
        case 'Overwrite',   save_mode = 'overwrite';
        case 'Save as new', save_mode = 'new';
        otherwise,          ok = false;
    end
end
end
