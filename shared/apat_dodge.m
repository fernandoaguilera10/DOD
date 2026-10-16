function offs = apat_dodge(n)
%APAT_DODGE  Horizontal offsets of the conditions at one x position.
%   All conditions are now plotted at their TRUE x (offsets are zero) so
%   every point sits exactly on its tick and on any curve drawn at the true
%   x (OAE sweeps, EFR spectra). Conditions are told apart by colour and
%   marker shape; the grey x-group bands (apat_xgroups) mark each tick's
%   area. Kept as a function so the plotting code stays unchanged, and so
%   a sideways offset can be brought back in one place if ever needed.
offs = zeros(1, max(n, 1));
end
