function o = oae_opts()
%OAE_OPTS  OAE options chosen on the Setup tab (with defaults).
%   Set by analysis_run (setappdata(0,'APAT_oae_opts',...)) before the OAE
%   analysis / summary runs; read by oae_band_avg, the *analysis functions,
%   oae_summary, plot_ind_oae and plot_avg_oae.
%
%   Band averaging (applied when results are summarized — no re-analysis):
%     .bands_per_oct  1 | 2 | 3 | 4   (1 = octave, 2 = ½ octave …)      2
%     .frange         [fmin fmax] kHz — band centres run from
%                     fmin·2^w to fmax·2^-w in steps of w = 1/bands_per_oct
%                     (the defaults give the original 9 half-octave bands)  [0.5 16]
%     .method         'snrw'   SNR-weighted mean of dB (weight = SNR_power²)
%                     'power'  mean of pressure², then dB
%                     'meandb' plain mean of dB values
%                     'median' median of dB values                      'snrw'
%     .snr_on         SNR criterion on/off                               true
%     .snr_min        points with OAE − NF below this (dB) are left out  6
%     .min_frac       % of points in a band that must pass; otherwise the
%                     band uses all points and is flagged (hollow)        50
%     .gate_avg       'include' | 'exclude' flagged bands in the average  'include'
%     .y_measure      'amp' (dB) | 'snr' (OAE − NF, dB)                   'amp'
%     .regions        region edges, kHz [Low | Mid | High]                [0.5 2 8 16]
%     .save_epl/.save_spl  units whose figures / average files are saved   true / true
%                     (TEOAE has SPL only; if none of the chosen units
%                     exists, the available one is saved)
%
%   Analysis (used only when the analysis runs / Reanalyze):
%     .dp_win   DPOAE window (s)                              0.25
%     .dp_npts  DPOAE frequency points                        512
%     .dp_ar    DPOAE artifact threshold (SD above median)    3
%     .sf_win   SFOAE window base (s; scales the f-dependent window)  0.038
%     .sf_npts  SFOAE frequency points                        512
%     .sf_ar    SFOAE artifact threshold (SD)                 4
%     .sf_hp    SFOAE high-pass cutoff (Hz)                   300
%     .sf_nf    'adjacent' (nearby frequencies) | 'subtraction'  'adjacent'
%     .te_hp    TEOAE high-pass cutoff (Hz)                   200
%     .te_trim  TEOAE trimmed mean (%)                        20
o = struct('bands_per_oct',2, 'frange',[0.5 16], 'method','snrw', ...
    'snr_on',true, 'snr_min',6, 'min_frac',50, 'gate_avg','include', ...
    'y_measure','amp', 'regions',[0.5 2 8 16], 'save_epl',true, 'save_spl',true, ...
    'dp_win',0.25, 'dp_npts',512, 'dp_ar',3, ...
    'sf_win',0.038, 'sf_npts',512, 'sf_ar',4, 'sf_hp',300, 'sf_nf','adjacent', ...
    'te_hp',200, 'te_trim',20);
if isappdata(0,'APAT_oae_opts')
    u = getappdata(0,'APAT_oae_opts');
    if isstruct(u)
        for f = fieldnames(o)'
            if isfield(u, f{1}) && ~isempty(u.(f{1})), o.(f{1}) = u.(f{1}); end
        end
    end
end
o.bands_per_oct = min(max(round(o.bands_per_oct), 1), 12);
o.frange  = sort(double(o.frange(:)'));
if numel(o.frange) ~= 2 || o.frange(1) <= 0, o.frange = [0.5 16]; end
o.method  = lower(char(o.method));
if ~any(strcmp(o.method, {'snrw','power','meandb','median'})), o.method = 'snrw'; end
o.snr_on  = logical(o.snr_on);
o.min_frac = min(max(double(o.min_frac), 0), 100);
o.gate_avg = lower(char(o.gate_avg));
o.y_measure = lower(char(o.y_measure));
r = sort(double(o.regions(:)'));
if numel(r) ~= 4 || any(r <= 0), r = [0.5 2 8 16]; end
o.regions = r;
o.save_epl = logical(o.save_epl);  o.save_spl = logical(o.save_spl);
if ~o.save_epl && ~o.save_spl, o.save_epl = true; o.save_spl = true; end
o.dp_npts = max(16, round(o.dp_npts));
o.sf_npts = max(16, round(o.sf_npts));
o.sf_nf   = lower(char(o.sf_nf));
end
