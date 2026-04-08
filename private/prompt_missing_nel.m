function nel_delay = prompt_missing_nel(nel_delay, Chins2Run, all_Conds2Run, nel_delay_file, nel_expected)
% prompt_missing_nel  GUI table to fill in NEL numbers for entries where
% both nel and delay_ms are unknown. Only shows entries that are expected
% to have data according to the chinroster (nel_expected). After
% confirmation, estimates the delay from the mean of known delays for the
% same NEL number.

cond_t_idx    = 1:length(all_Conds2Run);
fully_missing = isnan(nel_delay.nel) & isnan(nel_delay.delay_ms) & nel_expected;
nel_uncertain = ~isnan(nel_delay.nel) & ~nel_delay.nel_confirmed & nel_expected;

if ~any(fully_missing(:)) && ~any(nel_uncertain(:))
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
        elseif ~isnan(nel_delay.nel(s,t))
            tbl_data{s,ci} = num2str(nel_delay.nel(s,t));
        else
            tbl_data{s,ci} = '';
        end
    end
end

%% Figure
col_width = 90;
row_height = 22;
fig_w = max(520, 160 + nConds*col_width);
fig_h = max(300, 160 + nSubs*row_height);
scr   = get(0,'ScreenSize');
fig_x = round((scr(3)-fig_w)/2);
fig_y = round((scr(4)-fig_h)/2);

fig = figure('Name','Missing NEL Numbers','NumberTitle','off', ...
    'Position',[fig_x fig_y fig_w fig_h], ...
    'MenuBar','none','ToolBar','none','Resize','on');

uicontrol(fig,'Style','text', ...
    'String','Enter NEL (1 or 2) in red/yellow cells.  Green = confirmed.  Yellow = estimated (editable).  Grey = N/A.', ...
    'Units','normalized','Position',[0.02 0.88 0.96 0.10], ...
    'HorizontalAlignment','left','FontSize',10);

uit = uitable(fig, ...
    'Data',           tbl_data, ...
    'ColumnName',     cond_labels, ...
    'RowName',        Chins2Run, ...
    'ColumnWidth',    repmat({col_width},1,nConds), ...
    'ColumnEditable', true(1, nConds), ...
    'Units','normalized','Position',[0.02 0.14 0.96 0.73], ...
    'FontSize',11);

%% Cell styling
style_unavailable = uistyle('BackgroundColor',[0.91 0.91 0.93],'FontColor',[0.62 0.62 0.65]);                     % soft cool grey
style_confirmed   = uistyle('BackgroundColor',[0.82 0.96 0.86],'FontColor',[0.13 0.55 0.27],'FontWeight','bold'); % soft mint green (confirmed from MetaData)
style_uncertain   = uistyle('BackgroundColor',[1.00 0.97 0.75],'FontColor',[0.65 0.45 0.00],'FontWeight','bold'); % soft amber (estimated, editable)
style_missing     = uistyle('BackgroundColor',[1.00 0.87 0.85],'FontColor',[0.80 0.22 0.18],'FontWeight','bold'); % warm coral
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if ~nel_expected(s,t)
            addStyle(uit, style_unavailable, 'cell', [s, ci]);
        elseif fully_missing(s,t)
            addStyle(uit, style_missing, 'cell', [s, ci]);
        elseif nel_uncertain(s,t)
            addStyle(uit, style_uncertain, 'cell', [s, ci]);
        else
            addStyle(uit, style_confirmed, 'cell', [s, ci]);
        end
    end
end

uicontrol(fig,'Style','pushbutton','String','Confirm', ...
    'Units','normalized','Position',[0.35 0.02 0.30 0.09], ...
    'FontSize',11,'FontWeight','bold', ...
    'Callback',@(~,~) uiresume(fig));

uiwait(fig);
if ~ishandle(fig), return; end
updated = get(uit,'Data');
close(fig);

%% Write user inputs back (fully missing and uncertain entries)
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if fully_missing(s,t) || nel_uncertain(s,t)
            nel_num = str2double(updated{s,ci});
            if ismember(nel_num, [1 2])
                nel_delay.nel(s,t) = nel_num;
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
end
