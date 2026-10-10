function s = thr_freq_label(f)
%THR_FREQ_LABEL  'Click' for 0, otherwise '500 Hz' / '4 kHz' (matches ABR Peaks tabs).
if f == 0
    s = 'Click';
elseif f >= 1000
    s = sprintf('%.4g kHz', f/1000);
else
    s = sprintf('%.4g Hz', f);
end
end
