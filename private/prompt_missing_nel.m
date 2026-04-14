function nel_delay = prompt_missing_nel(nel_delay, Chins2Run, all_Conds2Run, nel_delay_file, nel_expected)
%PROMPT_MISSING_NEL  GUI table to fill in NEL numbers for entries where
%   both nel and delay_ms are unknown.  Only shows entries that are expected
%   to have data according to the chinroster (nel_expected).  After
%   confirmation, estimates the delay from the mean of known delays for the
%   same NEL number.
%
%   Requires uifigure (needed for uistyle/addStyle on uitable).
%   If you see a "Method Style not defined" error, restart MATLAB to clear
%   the class cache (known MATLAB bug: mathworks.com/answers/467384).

cond_t_idx      = 1:length(all_Conds2Run);
nel_confirmed   = nel_delay.nel_confirmed == 1 & nel_expected;
nel_needs_input = nel_delay.nel_confirmed == 0 & nel_expected;
nel_has_value   = nel_needs_input & ~isnan(nel_delay.nel);

if ~any(nel_needs_input(:)), return; end

%% Build table data
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
        if     ~nel_expected(s,t),                        tbl_data{s,ci} = 'N/A';
        elseif nel_confirmed(s,t) || nel_has_value(s,t),  tbl_data{s,ci} = num2str(nel_delay.nel(s,t));
        else,                                              tbl_data{s,ci} = '';
        end
    end
end

%% Layout constants
col_w  = 100;   row_h = 26;
fig_w  = max(640, 220 + nConds*col_w);
fig_h  = max(480, 300 + nSubs*row_h);
scr    = get(0,'ScreenSize');
fig_x  = round((scr(3)-fig_w)/2);
fig_y  = round((scr(4)-fig_h)/2);

clr_black = [0.08 0.08 0.08];
clr_gold  = [0.81 0.73 0.57];
clr_bg    = [0.97 0.96 0.93];

%% Figure
fig = uifigure('Name','ABR - NEL Delay', ...
    'Position',[fig_x fig_y fig_w fig_h], ...
    'Resize','on','Color',clr_bg);

% Header  (top 16%)
hp_h = round(0.16 * fig_h);
hp = uipanel(fig,'BorderType','none','BackgroundColor',clr_black, ...
    'Units','normalized','Position',[0 0.84 1 0.16]);
uilabel(hp,'Text','Data Collection Booth', ...
    'Position',[round(0.02*fig_w) round(0.52*hp_h) round(0.96*fig_w) round(0.42*hp_h)], ...
    'HorizontalAlignment','left','FontSize',17,'FontWeight','bold','FontColor',clr_gold);
uilabel(hp,'Text','Enter the recording setup used (NEL 1 or 2) for the missing cells (red).', ...
    'Position',[round(0.02*fig_w) round(0.04*hp_h) round(0.96*fig_w) round(0.42*hp_h)], ...
    'HorizontalAlignment','left','FontSize',12,'WordWrap','on', ...
    'FontColor',[0.88 0.84 0.74]);

% Table  (from 27% to 83%)
uit = uitable(fig, ...
    'Data',tbl_data,'ColumnName',cond_labels,'RowName',Chins2Run, ...
    'ColumnWidth',repmat({col_w},1,nConds),'ColumnEditable',true(1,nConds), ...
    'Units','normalized','Position',[0.02 0.27 0.96 0.56], ...
    'FontSize',13,'RowStriping','off','CellEditCallback',@validate_cell);

% Legend  (bottom-left, 24% tall)
legend_items = {
    [0.82 0.96 0.86], [0.13 0.55 0.27], 'Confirmed (read-only)';
    [1.00 0.97 0.75], [0.65 0.45 0.00], 'Manual (editable)';
    [1.00 0.87 0.85], [0.80 0.22 0.18], 'Missing — input required';
    [0.91 0.91 0.93], [0.50 0.50 0.52], 'Data Unavailable';
};
lp = uipanel(fig,'BorderType','line','BackgroundColor',clr_bg, ...
    'Title','Legend','FontSize',12, ...
    'Units','normalized','Position',[0.02 0.01 0.60 0.24]);

% Compute pixel dimensions of the inner area (subtract panel border + title)
lp_pw = round(0.58 * fig_w);   % usable inner pixel width
lp_ph = round(0.24 * fig_h) - 24;  % usable inner pixel height (minus title bar)
hw    = floor(lp_pw / 2);           % half width per column
hh    = floor(lp_ph / 2);           % half height per row
sw    = 16;  sh = 16;               % swatch size (px)
pad   = 8;

nLeg = size(legend_items,1);
for k = 1:nLeg
    col   = mod(k-1, 2);
    row   = floor((k-1) / 2);
    x0_px = col * hw + pad;
    y0_px = (1 - row) * hh + pad;   % row 0 = top half, row 1 = bottom half (y from bottom)
    % colour swatch (uipanel supports pixel positions)
    uipanel(lp, 'BackgroundColor',legend_items{k,1}, 'BorderType','none', ...
        'Position',[x0_px,  y0_px + round((hh - 2*pad - sh)/2),  sw,  sh]);
    % label (pixel position — uilabel has no Units property)
    uilabel(lp, 'Text', legend_items{k,3}, ...
        'Position',[x0_px + sw + 6,  y0_px,  hw - sw - pad - 10,  hh - 2*pad], ...
        'HorizontalAlignment','left', 'FontSize',12, 'FontWeight','bold', ...
        'FontColor',legend_items{k,2}, 'WordWrap','on');
end

% Save button  (bottom-right, compact height)
btn_h = 44;
btn_y = round(0.01*fig_h) + round((0.24*fig_h - btn_h) / 2);
uibutton(fig,'Text','Save', ...
    'Position',[round(0.65*fig_w), btn_y, round(0.33*fig_w), btn_h], ...
    'FontSize',15,'FontWeight','bold', ...
    'FontColor',clr_black,'BackgroundColor',clr_gold, ...
    'ButtonPushedFcn',@(~,~) uiresume(fig));

%% Cell styles
style_na        = uistyle('BackgroundColor',[0.91 0.91 0.93],'FontColor',[0.50 0.50 0.52]);
style_confirmed = uistyle('BackgroundColor',[0.82 0.96 0.86],'FontColor',[0.13 0.55 0.27],'FontWeight','bold');
style_manual    = uistyle('BackgroundColor',[1.00 0.97 0.75],'FontColor',[0.65 0.45 0.00],'FontWeight','bold');
style_missing   = uistyle('BackgroundColor',[1.00 0.87 0.85],'FontColor',[0.80 0.22 0.18],'FontWeight','bold');

for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if     ~nel_expected(s,t),  addStyle(uit, style_na,        'cell', [s ci]);
        elseif nel_confirmed(s,t),  addStyle(uit, style_confirmed, 'cell', [s ci]);
        elseif nel_has_value(s,t),  addStyle(uit, style_manual,    'cell', [s ci]);
        else,                       addStyle(uit, style_missing,    'cell', [s ci]);
        end
    end
end

%% Wait for user
uiwait(fig);
if ~isvalid(fig), return; end
updated = get(uit,'Data');
close(fig);

%% Write user inputs back
for s = 1:nSubs
    for ci = 1:nConds
        t = cond_t_idx(ci);
        if nel_needs_input(s,t)
            raw = strtrim(updated{s,ci});
            if isempty(raw)
                nel_delay.nel(s,t)          = NaN;
                nel_delay.delay_ms(s,t)     = NaN;
                nel_delay.is_estimated(s,t) = false;
            else
                nel_num = str2double(raw);
                if ismember(nel_num,[1 2])
                    nel_delay.nel(s,t) = nel_num;
                end
            end
        end
    end
end
save(nel_delay_file,'nel_delay');

%% Estimate delay for entries that now have a NEL number
for s = 1:nSubs
    for t = 1:length(all_Conds2Run)
        if isnan(nel_delay.delay_ms(s,t)) && ~isnan(nel_delay.nel(s,t))
            same_nel = nel_delay.nel == nel_delay.nel(s,t);
            known    = same_nel & ~isnan(nel_delay.delay_ms) & ~nel_delay.is_estimated;
            if any(known(:))
                nel_delay.delay_ms(s,t)     = mean(nel_delay.delay_ms(known),'omitnan');
                nel_delay.is_estimated(s,t) = true;
                parts = strsplit(all_Conds2Run{t},filesep);
                fprintf('  [NEL] ESTIMATED %s (%s): %.3f ms (NEL%d mean)\n', ...
                    Chins2Run{s}, parts{end}, nel_delay.delay_ms(s,t), nel_delay.nel(s,t));
            end
        end
    end
end
save(nel_delay_file,'nel_delay');

%% Nested: real-time cell validation
    function validate_cell(src, evt)
        r = evt.Indices(1);  c = evt.Indices(2);  t = cond_t_idx(c);
        if ~nel_needs_input(r,t)
            d = get(src,'Data');  d{r,c} = evt.PreviousData;  set(src,'Data',d);
            return
        end
        new_val = strtrim(evt.NewData);
        if isempty(new_val)
            addStyle(src, style_missing, 'cell', [r c]);
            return
        end
        nel_num = str2double(new_val);
        if ismember(nel_num,[1 2])
            addStyle(src, style_manual, 'cell', [r c]);
        else
            d = get(src,'Data');  d{r,c} = '';  set(src,'Data',d);
            addStyle(src, style_missing, 'cell', [r c]);
            uialert(fig,'Value must be 1 or 2.','Invalid NEL');
        end
    end

end
