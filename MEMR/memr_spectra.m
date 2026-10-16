function [f, R] = memr_spectra(memr)
%MEMR_SPECTRA  Reflex response of one MEMR result as levels x frequency.
%   f — frequency (Hz, row);  R — ear-canal pressure change (dB re. baseline),
%   one row per elicitor level (memr.elicitor order). Empty when the result
%   holds no spectra (older files).
f = [];  R = [];
if ~isstruct(memr) || ~isfield(memr,'freq') || ~isfield(memr,'MEM'), return; end
f = double(memr.freq(:)');  R = double(memr.MEM);
nL = numel(memr.elicitor);
if size(R,2) ~= numel(f) && size(R,1) == numel(f), R = R.'; end   % freq x levels -> levels x freq
if size(R,2) ~= numel(f), f = []; R = []; return; end
if size(R,1) ~= nL && size(R,2) == nL && numel(f) == nL, R = R.'; end
end
