function out = output_opts(app, action, varargin)
%OUTPUT_OPTS  Setup "Output" choices (Setup → 06 Output section, Oct 16 2026;
%   measure-specific plot defaults in the ABR / OAE / MEMR parameter panels).
%
%   s = output_opts(app, 'get')       struct from the controls:
%         .export_fmt   'mat' | 'csv' | 'both'
%         .plot         struct for apat_plot_defaults: save_images, dpi,
%                       subj_pts, shading, oae_sweep, oae_nf, resp_sd, abr_n
%   output_opts(app, 'set', s)        controls from a saved struct (same
%                                     fields; missing ones are left as they are;
%                                     an old .group field is ignored)
%   output_opts(app, 'refresh')       look of the toggles (.mat / .csv chips,
%                                     Images ON/OFF pill, dpi segments enabled
%                                     only when saving, plot-default toggles)
%   txt = output_opts(app, 'summary') short text for the Run Summary row
%
%   (The "Group:" field was removed Oct 16 2026: the Experiment — roster
%   sheet — is a column of every data file and averages of all Experiments
%   share one file per average in Analysis/<Measure>/Average/.)
%
%   Handles in app.h_output (built in createComponents>buildSetupTab):
%   mat_btn / csv_btn (state, export 'mat' | 'csv' | 'both'),
%   img_btn (ON/OFF), dpi300_btn / dpi150_btn (segments), chk.<field> plot
%   default toggles (subj_pts, shading in Output; abr_n in ABR, oae_sweep /
%   oae_nf in OAE, resp_sd in MEMR Parameters).
%   Run: RunButtonPushed>run_one copies 'get' into root appdata
%   'APAT_export_fmt' / 'APAT_plot_defaults', cfg.export_fmt and
%   app.state.plot_defaults. Saved in launcher_last_settings.mat as
%   export_fmt and plot_defaults (settings_ops).
out = [];
switch action
    case 'get',     out = do_get(app);
    case 'set',     do_set(app, varargin{1});  do_refresh(app);
    case 'refresh', do_refresh(app);
    case 'summary', do_refresh(app);  out = summary_text(do_get(app), true);
end
end


function s = do_get(app)
s = struct('export_fmt','mat', 'plot',apat_plot_defaults('defaults'));
O = handles(app);
if isempty(O), return; end
try
    m = logical(O.mat_btn.Value);  c = logical(O.csv_btn.Value);
    if m && c, s.export_fmt = 'both'; elseif c, s.export_fmt = 'csv'; else, s.export_fmt = 'mat'; end
catch
end
try, if isvalid(O.img_btn),   s.plot.save_images = logical(O.img_btn.Value); end, catch, end
try, if isvalid(O.dpi150_btn) && O.dpi150_btn.Value, s.plot.dpi = 150; else, s.plot.dpi = 300; end, catch, end
try
    f = fieldnames(O.chk);
    for k = 1:numel(f)
        if isfield(s.plot, f{k}) && isvalid(O.chk.(f{k})), s.plot.(f{k}) = logical(O.chk.(f{k}).Value); end
    end
catch
end
end


function do_set(app, s)
O = handles(app);
if isempty(O) || ~isstruct(s), return; end
try
    if isfield(s,'export_fmt') && any(strcmp({'mat','csv','both'}, s.export_fmt))
        O.mat_btn.Value = any(strcmp(s.export_fmt, {'mat','both'}));
        O.csv_btn.Value = any(strcmp(s.export_fmt, {'csv','both'}));
    end
catch
end
if ~isfield(s,'plot') || ~isstruct(s.plot), return; end
p = apat_plot_defaults('opts', s.plot);          % validated + completed
try, O.img_btn.Value = p.save_images; catch, end
try
    O.dpi150_btn.Value = isequal(p.dpi, 150);
    O.dpi300_btn.Value = ~O.dpi150_btn.Value;
catch
end
try
    f = fieldnames(O.chk);
    for k = 1:numel(f)
        if isfield(s.plot, f{k}), O.chk.(f{k}).Value = p.(f{k}); end
    end
catch
end
end


function do_refresh(app)
O = handles(app);
if isempty(O), return; end
try
    b = O.img_btn;
    setup_style(app, 'onoff', b);                     % ON green / OFF red
    for d = [O.dpi300_btn O.dpi150_btn]
        d.Enable = ternary_s(b.Value, 'on', 'off');
        setup_style(app, 'chip', d);
    end
    for d = [O.mat_btn O.csv_btn]
        setup_style(app, 'chip', d);
        d.Text = [ternary_s(d.Value, char(9632), char(9633)) ' ' char(d.UserData)];
    end
catch
end
try
    f = fieldnames(O.chk);
    for k = 1:numel(f), setup_style(app, 'pdef', O.chk.(f{k})); end
catch
end
end


function t = summary_text(s, long)
fmt = struct('mat','MAT', 'csv','CSV', 'both','MAT + CSV');
f = 'MAT';
try, f = fmt.(s.export_fmt); catch, end
if s.plot.save_images, img = sprintf('%d dpi', round(s.plot.dpi)); else, img = 'No Images'; end
if long
    if s.plot.save_images, img = sprintf('Images %d dpi', round(s.plot.dpi)); end
    t = sprintf('Data %s  |  %s', strrep(strrep(lower(f), 'mat', '.mat'), 'csv', '.csv'), img);
else
    t = sprintf('%s  ·  %s', f, img);
end
end


function O = handles(app)
O = [];
try
    if isstruct(app.h_output) && isfield(app.h_output, 'mat_btn'), O = app.h_output; end
catch
end
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
