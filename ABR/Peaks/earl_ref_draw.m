function earl_ref_draw(ax, t, inds_m, wave_sel, wave_clrs)
%EARL_REF_DRAW  Earl (1983) chinchilla latency ranges on the peak editor.
%
%   earl_ref_draw(ax, t, inds_m, wave_sel, wave_clrs)
%       Called by findPeaks_dtw/draw_edit after the waveform is plotted.
%       Draws one shaded band per wave (Earl range at the matching sensation
%       level) behind the waveform. Nothing is drawn when the reference is Off.
%   earl_ref_draw('refresh', fig)
%       Redraws the bands on the current editor axes (Ref dropdown changed).
%
%   Settings (appdata on the app figure):
%     'peak_ref_mode'  : 'Off' | 'Absolute' | 'Relative to Wave I'
%                        (older names 'Earl' / 'Earl re I' still accepted)
%     'peak_ref_level' : struct('lev',dB SPL, 'thr',visual threshold dB SPL,
%                               'freq',Hz (0 = click))  — set by ABR_dtw
%   Sensation level = level - visual threshold, rounded to the nearest 10 dB
%   and limited to 0–70 dB SL (the range Earl measured).
%   All drawn objects have HitTest 'off' (clicks still reach the axes) and
%   Tag 'earl_ref'.

if ischar(ax) && strcmp(ax, 'refresh')
    fig = t;
    ctx = getappdata(fig, 'peak_ref_ctx');
    if isempty(ctx) || ~isstruct(ctx) || ~isvalid(ctx.ax), return; end
    delete(findall(ctx.ax, 'Tag','earl_ref'));
    earl_ref_draw(ctx.ax, ctx.t, ctx.inds_m, ctx.wave_sel, ctx.wave_clrs);
    return;
end

fig = ancestor(ax, 'figure');
setappdata(fig, 'peak_ref_ctx', struct('ax',ax, 't',t, 'inds_m',inds_m, ...
    'wave_sel',wave_sel, 'wave_clrs',wave_clrs));
mode = 'Off';
if isappdata(fig,'peak_ref_mode'), mode = getappdata(fig,'peak_ref_mode'); end
if isempty(mode) || strcmp(mode, 'Off'), return; end

info = struct('lev',NaN, 'thr',NaN, 'freq',0);
if isappdata(fig,'peak_ref_level'), info = getappdata(fig,'peak_ref_level'); end
R  = earl_ref_data();
yl = ax.YLim;  xl = ax.XLim;
hold(ax, 'on');
caption = '';

sl = info.lev - info.thr;
if ~isfinite(sl)
    caption = 'Earl Ranges: Set A Threshold First (Sensation Level Is Not Known)';
elseif sl < -5
    caption = sprintf('Earl Ranges: %g dB SPL Is Below Threshold (%g dB SPL)', info.lev, info.thr);
else
    sl_use = min(70, max(0, round(sl/10)*10));
    li = find(R.sl == sl_use, 1);
    rel = any(strcmp(mode, {'Relative to Wave I','Earl re I'}));
    t1 = NaN;
    if rel
        if numel(inds_m) >= 1 && ~isnan(inds_m(1)), t1 = t(inds_m(1)); end
    end
    if rel && isnan(t1)
        caption = 'Relative To Wave I: Pick Wave I First (Or Restore It If Marked Absent)';
    else
        wl = {'I','II','III','IV','V'};
        for k = 1:min(5, numel(wave_sel))
            if ~wave_sel(k), continue; end
            if rel
                if k == 1
                    % Wave I: Earl's spread around his mean, centred on your Wave I
                    plot(ax, [t1 t1], yl, '--', 'Color',[wave_clrs(1,:) 0.8], 'LineWidth',1.5, ...
                        'HitTest','off', 'PickableParts','none', 'HandleVisibility','off', 'Tag','earl_ref');
                    lo = t1 + R.abs_min(li,1) - R.abs_mean(li,1);
                    hi = t1 + R.abs_max(li,1) - R.abs_mean(li,1);  mu = t1;
                else
                    lo = t1 + R.rel_min(li,k);  hi = t1 + R.rel_max(li,k);  mu = t1 + R.rel_mean(li,k);
                end
            else
                lo = R.abs_min(li,k);  hi = R.abs_max(li,k);  mu = R.abs_mean(li,k);
            end
            if ~isfinite(lo), continue; end                 % no response at this SL
            if hi - lo < 0.04, lo = mu - 0.02; hi = mu + 0.02; end   % single animal
            c = wave_clrs(k,:);
            patch(ax, [lo hi hi lo], [yl(1) yl(1) yl(2) yl(2)], c, 'FaceAlpha',0.12, ...
                'EdgeColor',c, 'EdgeAlpha',0.35, 'LineStyle',':', ...
                'HitTest','off', 'PickableParts','none', 'HandleVisibility','off', 'Tag','earl_ref');
            if ~(rel && k == 1)     % Wave I in relative mode already has the dashed line
                plot(ax, [mu mu], yl, ':', 'Color',[c 0.7], 'LineWidth',1.2, ...
                    'HitTest','off', 'PickableParts','none', 'HandleVisibility','off', 'Tag','earl_ref');
            end
            if mu >= xl(1) && mu <= xl(2)
                % Label just right of the mean line, so the line does not cross the text
                text(ax, mu + 0.008*diff(xl), yl(1) + 0.10*diff(yl), wl{k}, 'Color',c, 'FontWeight','bold', ...
                    'FontSize',12, 'HorizontalAlignment','left', 'VerticalAlignment','bottom', ...
                    'HitTest','off', 'PickableParts','none', 'Tag','earl_ref');
            end
        end
        % Short caption; details (offset, tone bursts, >70 dB SL) are in the ? help
        if rel
            caption = sprintf('Earl (1983) Interpeak Ranges Relative To Wave I At %g dB SPL (%d dB SL). See ? For More Details.', ...
                info.lev, sl_use);
        else
            caption = sprintf('Earl (1983) Latency Ranges At %g dB SPL (%d dB SL). See ? For More Details.', ...
                info.lev, sl_use);
        end
    end
end
if ~isempty(caption)
    text(ax, xl(1) + 0.01*diff(xl), yl(1) + 0.03*diff(yl), caption, ...
        'FontSize',11, 'Color',[0.35 0.35 0.35], 'BackgroundColor','w', 'Margin',2, ...
        'VerticalAlignment','bottom', 'Interpreter','none', ...
        'HitTest','off', 'PickableParts','none', 'Tag','earl_ref');
end
% Keep the bands behind the waveform and markers
h = findall(ax, 'Tag','earl_ref', 'Type','patch');
if ~isempty(h), uistack(h, 'bottom'); end
ax.YLim = yl;  ax.XLim = xl;
end
