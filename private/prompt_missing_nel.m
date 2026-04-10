function nel_delay = prompt_missing_nel(nel_delay, Chins2Run, all_Conds2Run, nel_delay_file, nel_expected)
% prompt_missing_nel  GUI table to fill in NEL numbers for entries where
% both nel and delay_ms are unknown. Only shows entries that are expected
% to have data according to the chinroster (nel_expected). After
% confirmation, estimates the delay from the mean of known delays for the
% same NEL number.

cond_t_idx      = 1:length(all_Conds2Run);
nel_confirmed   = nel_delay.nel_confirmed == 1 & nel_expected;   % green
nel_needs_input = nel_delay.nel_confirmed == 0 & nel_expected;   % red or amber (needs manual entry)
nel_has_value   = nel_needs_input & ~isnan(nel_delay.nel);       % amber (value present but not confirmed)

if ~any(nel_needs_input(:))
    return
end

%% Build table
cond_labels = cell(1, length(cond_t_idx));
for ci = 1:length(cond_t_idx)
    parts = strsplit(all_Conds2Run{cond_t_idx(ci)}, filesep);
    cond_labels{ci} = parts{end};
end

nSubs  = length(Chins2Run);
nConds = length(cond_t_idx);
tbl_data = cell(nSubs, nConds);
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if ~nel_expected(s,t)
            tbl_data{s,ci} = 'N/A';
        elseif nel_confirmed(s,t) || nel_has_value(s,t)
            tbl_data{s,ci} = num2str(nel_delay.nel(s,t));
        else
            tbl_data{s,ci} = '';
        end
    end
end

%% Figure
col_width  = 100;
row_height = 26;
fig_w = max(600, 220 + nConds*col_width);
fig_h = max(420, 260 + nSubs*row_height);
scr   = get(0,'ScreenSize');
fig_x = round((scr(3)-fig_w)/2);
fig_y = round((scr(4)-fig_h)/2);

% Purdue University palette (UI chrome only)
clr_black  = [0.08 0.08 0.08];   % Purdue Black
clr_gold   = [0.81 0.73 0.57];   % Purdue Old Gold  (#CFB991)
clr_bg     = [0.97 0.96 0.93];   % warm off-white background

% ── UI text ─────────────────────────────────────────────────────────────
txt_window_title  = 'ABR - NEL Delay';
txt_header_title  = 'Data Collection Booth';
txt_header_sub    = 'Enter the recording setup used (NEL 1 or 2) for the missing cells (red).';
txt_confirm_btn   = 'Save';
txt_legend_title  = 'Legend';
txt_legend_items  = {'Confirmed (read-only)', 'Manual (editable)', ...
                     'Missing — input required', 'Data Unavailable'};
txt_error_msg     = 'Value must be 1 or 2.';
txt_error_title   = 'Invalid NEL';
% ────────────────────────────────────────────────────────────────────────

fig = figure('Name',txt_window_title,'NumberTitle','off', ...
    'Position',[fig_x fig_y fig_w fig_h], ...
    'MenuBar','none','ToolBar','none','Resize','on', ...
    'Color',clr_bg);

% ── Header bar ──────────────────────────────────────────────────────────
hp = uipanel(fig,'BorderType','none','BackgroundColor',clr_black, ...
    'Units','normalized','Position',[0 0.87 1 0.13]);
uicontrol(hp,'Style','text','String',txt_header_title, ...
    'Units','normalized','Position',[0.02 0.52 0.96 0.42], ...
    'HorizontalAlignment','left','FontSize',14,'FontWeight','bold', ...
    'ForegroundColor',clr_gold,'BackgroundColor',clr_black);
uicontrol(hp,'Style','text','String',txt_header_sub, ...
    'Units','normalized','Position',[0.02 0.04 0.96 0.42], ...
    'HorizontalAlignment','left','FontSize',9.5, ...
    'ForegroundColor',[0.88 0.84 0.74],'BackgroundColor',clr_black);

% ── Table ───────────────────────────────────────────────────────────────
uit = uitable(fig, ...
    'Data',           tbl_data, ...
    'ColumnName',     cond_labels, ...
    'RowName',        Chins2Run, ...
    'ColumnWidth',    repmat({col_width},1,nConds), ...
    'ColumnEditable', true(1,nConds), ...
    'Units','normalized','Position',[0.02 0.18 0.96 0.67], ...
    'FontSize',12, ...
    'RowStriping','off', ...
    'CellEditCallback', @validate_cell);

% ── Legend ──────────────────────────────────────────────────────────────
legend_items = {
    [0.82 0.96 0.86], [0.13 0.55 0.27], txt_legend_items{1};
    [1.00 0.97 0.75], [0.65 0.45 0.00], txt_legend_items{2};
    [1.00 0.87 0.85], [0.80 0.22 0.18], txt_legend_items{3};
    [0.91 0.91 0.93], [0.50 0.50 0.52], txt_legend_items{4};
};
lp = uipanel(fig,'BorderType','line','HighlightColor',clr_gold, ...
    'BackgroundColor',clr_bg,'Title',txt_legend_title,'FontSize',9, ...
    'Units','normalized','Position',[0.02 0.01 0.60 0.16]);
n_items = size(legend_items,1);
for k = 1:n_items
    x0 = 0.02 + (k-1)*(1/n_items);
    w  = 1/n_items - 0.02;
    uicontrol(lp,'Style','text','String','  ', ...
        'Units','normalized','Position',[x0 0.30 0.035 0.50], ...
        'BackgroundColor',legend_items{k,1});
    uicontrol(lp,'Style','text','String',legend_items{k,3}, ...
        'Units','normalized','Position',[x0+0.04 0.20 w-0.04 0.60], ...
        'HorizontalAlignment','left','FontSize',8.5, ...
        'ForegroundColor',legend_items{k,2},'BackgroundColor',clr_bg);
end

% ── Confirm button ───────────────────────────────────────────────────────
uicontrol(fig,'Style','pushbutton','String',txt_confirm_btn, ...
    'Units','normalized','Position',[0.68 0.03 0.28 0.12], ...
    'FontSize',12,'FontWeight','bold', ...
    'ForegroundColor',clr_black,'BackgroundColor',clr_gold, ...
    'Callback',@(~,~) uiresume(fig));

%% Cell styling
style_unavailable = uistyle('BackgroundColor',[0.91 0.91 0.93],'FontColor',[0.50 0.50 0.52], ...
    'HorizontalAlignment','center');                                          % grey  — N/A
style_confirmed   = uistyle('BackgroundColor',[0.82 0.96 0.86],'FontColor',[0.13 0.55 0.27], ...
    'FontWeight','bold','HorizontalAlignment','center');                      % green — confirmed
style_uncertain   = uistyle('BackgroundColor',[1.00 0.97 0.75],'FontColor',[0.65 0.45 0.00], ...
    'FontWeight','bold','HorizontalAlignment','center');                      % amber — value entered
style_missing     = uistyle('BackgroundColor',[1.00 0.87 0.85],'FontColor',[0.80 0.22 0.18], ...
    'FontWeight','bold','HorizontalAlignment','center');                      % red   — missing
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if ~nel_expected(s,t)
            addStyle(uit, style_unavailable, 'cell', [s, ci]);
        elseif nel_confirmed(s,t)
            addStyle(uit, style_confirmed, 'cell', [s, ci]);
        elseif nel_has_value(s,t)
            addStyle(uit, style_uncertain, 'cell', [s, ci]);
        else
            addStyle(uit, style_missing, 'cell', [s, ci]);
        end
    end
end

uiwait(fig);
if ~ishandle(fig), return; end
updated = get(uit,'Data');
close(fig);

%% Write user inputs back (fully missing and uncertain entries)
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if nel_needs_input(s,t)
            raw = strtrim(updated{s,ci});
            if isempty(raw)
                % User cleared the cell — reset fully so stale delay is not reused
                nel_delay.nel(s,t)          = NaN;
                nel_delay.delay_ms(s,t)     = NaN;
                nel_delay.is_estimated(s,t) = false;
            else
                nel_num = str2double(raw);
                if ismember(nel_num, [1 2])
                    nel_delay.nel(s,t) = nel_num;
                end
                % Invalid values were already rejected by CellEditCallback
            end
        end
    end
end

% Save immediately so user-provided NEL numbers are on record
save(nel_delay_file, 'nel_delay');

%% Estimate delay for entries that now have a NEL number
for s = 1:nSubs
    for t = 1:length(all_Conds2Run)
        if isnan(nel_delay.delay_ms(s,t)) && ~isnan(nel_delay.nel(s,t))
            same_nel = nel_delay.nel == nel_delay.nel(s,t);
            known    = same_nel & ~isnan(nel_delay.delay_ms) & ~nel_delay.is_estimated;
            if any(known(:))
                nel_delay.delay_ms(s,t)     = mean(nel_delay.delay_ms(known), 'omitnan');
                nel_delay.is_estimated(s,t) = true;
                parts = strsplit(all_Conds2Run{t}, filesep);
                fprintf('  [NEL] ESTIMATED %s (%s): %.3f ms (NEL%d mean)\n', ...
                    Chins2Run{s}, parts{end}, nel_delay.delay_ms(s,t), nel_delay.nel(s,t));
            end
        end
    end
end

save(nel_delay_file, 'nel_delay');

%% Nested: validate NEL cell edits in real time
    function validate_cell(src, evt)
        r   = evt.Indices(1);
        c   = evt.Indices(2);
        t   = cond_t_idx(c);
        % Revert if cell is confirmed (green) or N/A (grey)
        if ~nel_needs_input(r,t)
            d      = get(src, 'Data');
            d{r,c} = evt.PreviousData;
            set(src, 'Data', d);
            return
        end
        new_val = strtrim(evt.NewData);
        if isempty(new_val)
            % User cleared the cell — turn red
            addStyle(src, style_missing, 'cell', [r, c]);
            return
        end
        nel_num = str2double(new_val);
        if ismember(nel_num, [1 2])
            % Valid manual input — turn amber
            addStyle(src, style_uncertain, 'cell', [r, c]);
        else
            % Invalid — reset to blank, keep red, warn
            d      = get(src, 'Data');
            d{r,c} = '';
            set(src, 'Data', d);
            addStyle(src, style_missing, 'cell', [r, c]);
            errordlg(txt_error_msg, txt_error_title, 'modal');
        end
    end

end
