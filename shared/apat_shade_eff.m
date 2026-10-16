function c = apat_shade_eff(t)
%APAT_SHADE_EFF  Colour a band of shade t (apat_xgroups, 50 % opacity) shows
%   on white — for table rows / patches drawn opaque that must match it.
%   With no input: the plain band (no region) shade.
if nargin < 1 || isempty(t), c = [0.94 0.94 0.94]; return; end
c = 1 - 0.5 * (1 - double(t(:,1:3)));
end
