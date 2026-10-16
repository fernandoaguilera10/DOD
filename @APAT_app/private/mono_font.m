function f = mono_font()
%MONO_FONT  Monospaced font for APAT's "pixel" captions (header sign, Run
%   Summary captions / numbers, Run Analysis button, ON/OFF pills, run
%   card): the first installed of Menlo (macOS), Consolas (Windows), Courier
%   New, DejaVu Sans Mono; 'monospaced' otherwise. Cached in root appdata
%   'APAT_mono_font' (listfonts is read once per MATLAB session).
f = 'monospaced';
try
    if isappdata(0, 'APAT_mono_font')
        f = getappdata(0, 'APAT_mono_font');
        return;
    end
    have = listfonts();
    for c = {'Menlo','Consolas','Courier New','DejaVu Sans Mono','Courier'}
        if any(strcmpi(have, c{1})), f = c{1}; break; end
    end
    setappdata(0, 'APAT_mono_font', f);
catch
end
end
