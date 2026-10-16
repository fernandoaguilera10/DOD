function [ms, sa] = apat_ms(ax, step_data)
%APAT_MS  Marker size for condition means (same size as the ABR Thresholds
%   average, 20 pt) — reduced only where the dodge step between conditions
%   is too narrow for 20 pt markers to sit side by side without touching
%   (dense axes: OAE bands, EFR harmonics, dAM bands …). Never below 10 pt.
%   step_data — distance between neighbouring conditions in x data units
%               (log10 units on a log axis). Call after XLim is set.
%   sa        — matching scatter area for the subject points (90 at 20 pt).
ms = 20;
try
    if nargin >= 2 && isfinite(step_data) && step_data > 0
        xl = double(ax.XLim);
        if strcmp(ax.XScale, 'log'), span = log10(xl(2)/xl(1)); else, span = diff(xl); end
        p  = getpixelposition(ax);
        px = step_data / span * p(3);              % pixels between neighbours
        ms = min(20, max(10, round(0.8 * px)));    % 1 pt ≈ 1.33 px → just apart
    end
catch
    ms = 20;
end
sa = max(36, round(90 * (ms/20)^2));
end
