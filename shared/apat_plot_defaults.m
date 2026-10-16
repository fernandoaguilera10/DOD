function out = apat_plot_defaults(action, varargin)
%APAT_PLOT_DEFAULTS  Setup "Output" choices: image saving and the plot
%   features that saved images and the first Results view start with.
%
%   opts = apat_plot_defaults('opts')       current choices (root appdata
%                                           'APAT_plot_defaults', set by
%                                           RunButtonPushed>run_one; safe
%                                           defaults for missing fields)
%   opts = apat_plot_defaults('opts', s)    same, completing struct s instead
%   opts = apat_plot_defaults('defaults')   the built-in defaults
%   apat_plot_defaults('apply', fh, view_key [, opts])
%                                           hide the features switched OFF in
%                                           figure (or container) fh before it
%                                           is saved / embedded (features ON
%                                           are left as the plot code drew them)
%
%   Fields (logical unless noted):
%     save_images  write PNGs (apat_save_fig)                     true
%     dpi          PNG resolution, 150 or 300 (number)            300
%     subj_pts     subject points on averages                     true
%     shading      x-group bands (Tag apat_xgroup)                true
%     oae_sweep    OAE sweep traces (Tag oae_raw)                 true
%     oae_nf       OAE noise floor (Tag oae_nf)                   true
%     resp_sd      MEMR Growth Response mean ± SD (memr_resp_sd)  true
%     abr_n        ABR Peaks sample size labels (abr_n_lbl)       true
%
%   'apply' works from the same Tags the Results Plot Settings strips use
%   (embed_results), so it does not depend on the exact view_key; view_key
%   is accepted for future per-view rules. It never throws.
if nargin < 1, action = 'opts'; end
switch lower(action)
    case 'defaults'
        out = defaults();
    case 'opts'
        s = [];
        if nargin >= 2 && isstruct(varargin{1})
            s = varargin{1};
        else
            try, s = getappdata(0, 'APAT_plot_defaults'); catch, end
        end
        out = complete(s);
    case 'apply'
        out = [];
        if nargin < 2, return; end
        vk = '';  if nargin >= 3, vk = varargin{2}; end
        try
            if nargin >= 4 && isstruct(varargin{3})
                o = complete(varargin{3});
            else
                o = apat_plot_defaults('opts');
            end
            do_apply(varargin{1}, vk, o);
        catch
        end
    otherwise
        out = [];
end
end


function d = defaults()
d = struct('save_images',true, 'dpi',300, 'subj_pts',true, 'shading',true, ...
    'oae_sweep',true, 'oae_nf',true, 'resp_sd',true, 'abr_n',true);
end


function o = complete(s)
%COMPLETE  Defaults, overwritten by the valid fields of s.
o = defaults();
if ~isstruct(s) || isempty(s), return; end
s = s(1);
f = fieldnames(o);
for k = 1:numel(f)
    if ~isfield(s, f{k}), continue; end
    v = s.(f{k});
    if strcmp(f{k}, 'dpi')
        if isnumeric(v) && isscalar(v) && isfinite(v) && v >= 50 && v <= 1200, o.dpi = double(v); end
    elseif (islogical(v) || isnumeric(v)) && isscalar(v)
        o.(f{k}) = logical(v);
    end
end
end


function do_apply(fh, view_key, o) %#ok<INUSL>
if isempty(fh) || ~all(isgraphics(fh)), return; end
% Tag → flag (the Tags the Plot Settings strips switch)
map = {'apat_xgroup',   'shading'; ...
       'oae_raw',       'oae_sweep'; ...
       'oae_nf',        'oae_nf'; ...
       'memr_resp_sd',  'resp_sd'; ...
       'abr_n_lbl',     'abr_n'; ...
       'thr_subj_pts',  'subj_pts'; ...
       'memr_subj_pts', 'subj_pts'; ...
       'efr_subj_pts',  'subj_pts'; ...
       'oae_subj_pts',  'subj_pts'; ...
       'abr_subj_pts',  'subj_pts'};
for f = fh(:)'
    for k = 1:size(map, 1)
        try
            H = findall(f, 'Tag', map{k,1});
            if isempty(H), continue; end
            if ~o.(map{k,2}), set(H, 'Visible', 'off'); end
        catch
        end
    end
end
end
