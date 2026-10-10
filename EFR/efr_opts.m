function o = efr_opts()
%EFR_OPTS  EFR analysis options chosen on the Setup tab (with defaults).
%   Set by analysis_run (setappdata(0,'APAT_efr_opts',...)) before the EFR
%   summary runs; read by avg_efr, plot_ind_efr, plot_avg_efr(_tabs) and
%   EFRsummary.
%     .low        [from to]  harmonic numbers for the "low" sum   (1 = 223 Hz)  [1 4]
%     .high       [from to]  harmonic numbers for the "high" sum              [5 16]
%     .measure    'amplitude' (PLV) | 'snr' (PLV SNR, dB)                    'amplitude'
%     .normalize  true → low/high divided by the same measure summed over
%                 all harmonics                                              false
%     .dam_bands  number of dAM smoothing bands                              16
o = struct('low',[1 4], 'high',[5 16], 'measure','amplitude', 'normalize',false, 'dam_bands',16);
if isappdata(0,'APAT_efr_opts')
    u = getappdata(0,'APAT_efr_opts');
    if isstruct(u)
        for f = fieldnames(o)'
            if isfield(u, f{1}) && ~isempty(u.(f{1})), o.(f{1}) = u.(f{1}); end
        end
    end
end
o.low  = sort(round(o.low(:)'));   o.high = sort(round(o.high(:)'));
o.measure = lower(char(o.measure));
o.dam_bands = max(2, round(o.dam_bands));
end
