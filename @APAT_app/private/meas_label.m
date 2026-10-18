function lbl = meas_label(app, m, k)
%MEAS_LABEL  Results label of analysis [measure m, type k] — as
%   RunButtonPushed>run_one: 'ABR Thresholds', 'EFR dAM', 'DPOAE', 'MEMR'
%   (ART), 'MEMR Vector' …
name = app.MEASURES(m).name;  subs = app.MEASURES(m).subtypes;
t = '';  if ~isempty(subs), t = subs{k}; end
if strcmp(name, 'MEMR') && k == 1, t = ''; end
switch name
    case {'ABR','EFR'}, lbl = [name ' ' t];
    case 'OAE',         lbl = t;
    case 'MEMR',        lbl = 'MEMR';  if ~isempty(t), lbl = ['MEMR ' t]; end
    otherwise,          lbl = name;
end
end
