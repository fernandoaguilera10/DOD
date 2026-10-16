function oae_legends(fh, ax, hC, LC, keys, x0, wid)
%OAE_LEGENDS  Kept for compatibility — bottom legends now come from
%   apat_legend (Code Archive root), shared by every measure. hC are the
%   condition handles already drawn; their colour / marker are reused.
C = struct('clr',{},'shp',{},'label',{});
for k = 1:numel(hC)
    C(k) = struct('clr',hC(k).Color(1:3), 'shp',hC(k).Marker, 'label',LC{k}); %#ok<AGROW>
end
delete(hC);
apat_legend(fh, ax, C, keys, x0, wid);
end
