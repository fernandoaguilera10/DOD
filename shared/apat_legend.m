function apat_legend(fh, ax, C, keys, x0, wid)
%APAT_LEGEND  Legends at the bottom of a figure, centred under the plot area
%   [x0, x0+wid] (normalized). Same look for every measure (OAE style):
%     upper row — conditions: line + marker in the condition colour
%     lower row — line keys (Noise floor, EPL / SPL, …), on an invisible
%                 helper axes (Tag 'apat_leg_ax'; one legend per axes)
%   C     struct array .clr .shp .label  (.shp '' = line only; .ls optional)
%   keys  struct array .args (plot arguments for a dummy line), .label
%   With no keys the condition row sits lower (single row).
if nargin < 4, keys = struct('args',{},'label',{}); end
if nargin < 5 || isempty(x0), x0 = 0.06; end
if nargin < 6 || isempty(wid), wid = 0.74; end
FS = 13;
two = ~isempty(keys);
if ~isempty(C)
    hold(ax, 'on');
    hC = gobjects(1, numel(C));
    for k = 1:numel(C)
        shp = strtrim(char(C(k).shp));  if isempty(shp), shp = 'none'; end
        ls = '-';  if isfield(C, 'ls') && ~isempty(C(k).ls), ls = C(k).ls; end
        hC(k) = plot(ax, NaN, NaN, 'LineStyle',ls, 'Marker',shp, 'MarkerSize',10, 'LineWidth',2, ...
            'Color',C(k).clr, 'MarkerFaceColor',C(k).clr, 'MarkerEdgeColor',C(k).clr, ...
            'Tag','apat_leg_item');
    end
    lg = legend(ax, hC, {C.label}, 'Orientation','horizontal', 'Box','off', 'FontSize',FS, ...
        'Location','none', 'Interpreter','none', 'AutoUpdate','off');
    lg.Tag = 'apat_legend';
    if two, place(lg, 0.058); else, place(lg, 0.025); end
end
if two
    axK = axes(fh, 'Position',[x0 0.005 wid 0.01], 'Visible','off', 'Tag','apat_leg_ax', ...
        'HitTest','off', 'PickableParts','none');
    hold(axK, 'on');
    hK = gobjects(1, numel(keys));
    for k = 1:numel(keys)
        hK(k) = plot(axK, NaN, NaN, keys(k).args{:});
    end
    lgK = legend(axK, hK, {keys.label}, 'Orientation','horizontal', 'Box','off', ...
        'FontSize',FS-1, 'Location','none', 'Interpreter','none', 'AutoUpdate','off');
    lgK.Tag = 'apat_legend';
    place(lgK, 0.012);
end

    function place(lg, ybot)
        set(lg, 'Units','normalized');  lp = get(lg, 'Position');
        set(lg, 'Position', [x0 + (wid - lp(3))/2, ybot, lp(3), lp(4)]);
    end
end
