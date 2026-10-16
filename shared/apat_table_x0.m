function x0 = apat_table_x0(ax, labels, fs_lab, vals, fs_val, n_sub, x_lab, x0_min, gap_px)
%APAT_TABLE_X0  Left edge (data units, axes XLim [0 1]) of the value columns
%   of a text table drawn in axes AX, so the widest row label (drawn at
%   x = X_LAB, FontSize FS_LAB) ends at least GAP_PX pixels before the
%   left edge of the widest value (FontSize FS_VAL) in the first of N_SUB
%   equal sub-columns between x0 and 1 (values centred in their column).
%
%   x0 = apat_table_x0(ax, labels, fs_lab, vals, fs_val, n_sub, x_lab, x0_min, gap_px)
%   Never below X0_MIN (the designed value), never above 0.6. Text extents
%   are measured with temporary texts (deleted again); on any failure the
%   designed X0_MIN is returned. Used by the EFR RAM individual, OAE
%   individual and ABR Thresholds summary tables.
if nargin < 9 || isempty(gap_px), gap_px = 8; end
x0 = x0_min;
try
    ap = getpixelposition(ax);  wpx = ap(3);
    if ~(wpx > 20), return; end
    eL = max_ext(ax, labels, fs_lab) * 1.08;     % small safety margin (rendering differences)
    eV = max_ext(ax, vals, fs_val) * 1.08;
    gap = gap_px / wpx;
    n = max(1, n_sub);
    R = x_lab + eL + gap + eV/2;                 % first value centre must be right of R
    % centre = x0 + (1 - x0)/(2n)  >=  R
    need = (R - 1/(2*n)) / (1 - 1/(2*n));
    if isfinite(need), x0 = min(0.6, max(x0_min, need)); end
catch
    x0 = x0_min;
end
end

function e = max_ext(ax, strs, fs)
e = 0;
if ischar(strs), strs = {strs}; end
for k = 1:numel(strs)
    t = text(ax, 0, 0.5, strs{k}, 'FontSize',fs, 'Units','data', 'Visible','off', ...
        'Interpreter','none', 'HandleVisibility','off');
    try
        ex = t.Extent;  e = max(e, ex(3));
    catch
    end
    delete(t);
end
end
