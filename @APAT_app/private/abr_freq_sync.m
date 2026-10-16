function abr_freq_sync(app, action, varargin)
%ABR_FREQ_SYNC  Separate ABR frequency selections for Thresholds and Peaks.
%   The Setup frequency chips always show the selection of the ABR type on
%   screen; app.state.abr_freq{1} = Thresholds, {2} = Peaks (logical 1×6:
%   Click, 0.5, 1, 2, 4, 8 kHz). So e.g. Peaks can run 4 kHz only while
%   Thresholds runs every frequency.
%   abr_freq_sync(app, 'store')        chips → selection of the type on screen
%   abr_freq_sync(app, 'load')         selection of the type on screen → chips
%   abr_freq_sync(app, 'all' | 'none') select / clear every chip, then store
%   abr_freq_sync(app, 'from_saved', s)  read s.abr_freq ({thr, peaks}) or the
%                                      old single s.abr_freq_sel (→ both types)
%   sel = app.state.abr_freq{k} is used by RunButtonPushed and update_summary.
nf = numel(app.h_abr_freq_checks);
if nf == 0, return; end
if ~isfield(app.state, 'abr_freq') || ~iscell(app.state.abr_freq) || numel(app.state.abr_freq) ~= 2
    app.state.abr_freq = {true(1,nf), true(1,nf)};
end
k = 1;
if app.state.measure_idx == 1 && app.state.subtype_idx == 2, k = 2; end
switch action
    case 'store'
        app.state.abr_freq{k} = chip_vals();
    case 'load'
        v = app.state.abr_freq{k};
        for fi = 1:nf
            if isgraphics(app.h_abr_freq_checks(fi)) && fi <= numel(v)
                app.h_abr_freq_checks(fi).Value = logical(v(fi));
            end
        end
        try
            lbl = findall(app.h_abr_param_panel, 'Tag','abr_freq_lbl');
            if ~isempty(lbl)
                lbl(1).Text = ternary(k == 1, 'Frequencies — Thresholds', 'Frequencies — Peaks');
            end
        catch
        end
    case {'all','none'}
        for fi = 1:nf
            if isgraphics(app.h_abr_freq_checks(fi)), app.h_abr_freq_checks(fi).Value = strcmp(action,'all'); end
        end
        app.state.abr_freq{k} = chip_vals();
    case 'from_saved'
        s = varargin{1};
        if isfield(s,'abr_freq') && iscell(s.abr_freq) && numel(s.abr_freq) == 2
            for j = 1:2
                v = logical(s.abr_freq{j}(:)');  w = true(1,nf);  w(1:min(nf,numel(v))) = v(1:min(nf,numel(v)));
                app.state.abr_freq{j} = w;
            end
        elseif isfield(s,'abr_freq_sel') && ~isempty(s.abr_freq_sel)
            v = logical(s.abr_freq_sel(:)');  w = true(1,nf);  w(1:min(nf,numel(v))) = v(1:min(nf,numel(v)));
            app.state.abr_freq = {w, w};
        end
        abr_freq_sync(app, 'load');
end

    function v = chip_vals()
        v = arrayfun(@(c) isgraphics(c) && logical(c.Value), app.h_abr_freq_checks);
    end
end
