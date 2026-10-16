function varargout = apat_data_dictionary(varargin)
%APAT_DATA_DICTIONARY  Every column (and Metric) APAT's CSV / table export can emit.
%
%   T = apat_data_dictionary()
%       table Column, Description, Type, Units, Measures. Rows "Metric=<id>"
%       describe each value of the Metric column (Units = units of Value).
%   apat_data_dictionary(file)
%       writes T to file (apat_write_csv; apat_csv writes
%       Analysis/APAT_data_dictionary.csv with the first CSV of a run).
%   [name, units] = apat_data_dictionary('mx', key)
%       Metric id + units of an exploratory MEMR (mx_data) key, e.g.
%       'V' → 'VectorChange', '%' (unknown key → key, '').
%
%   Schema (one observation per row; NaN written as an empty cell):
%     per recording   Measure, Experiment, Subject, Sex, Condition, keys…,
%                     Metric, Value, Units
%     *_Individual    Measure, Experiment, Subject, Sex, Condition, Reference,
%                     Excluded, keys…, Metric, Value, Units
%     average (.csv)  Measure, Experiment, Condition, Reference, keys…, Metric,
%                     Mean, SD, N, Units (statistics per Experiment × cell)
%   Average files hold every Experiment (one file per average type).
if nargin >= 1 && ischar(varargin{1}) && strcmp(varargin{1}, 'mx')
    [varargout{1}, varargout{2}] = mx_name(varargin{2});
    return
end
T = build();
if nargin >= 1 && ~isempty(varargin{1}), apat_write_csv(T, varargin{1}); end
if nargout > 0, varargout{1} = T; end
end


function T = build()
ABR = 'ABR_Thresholds;ABR_Peaks';  OAE = 'DPOAE;SFOAE;TEOAE';
MX  = 'MEMR_Vector;MEMR_Growth;MEMR_Kinetics;MEMR_Spectral;MEMR_Absorbance;MEMR_Probe;MEMR_Quality';
ALL = 'all';
C = {
% Column            Description                                                                     Type       Units      Measures
'Measure',          'Measure / view the row belongs to (files of different measures can be stacked)', 'text',  '',        ALL
'Experiment',       'Experiment = chinroster sheet of the run (e.g. NOISE, BLAST); average files hold every Experiment, statistics are per Experiment (never pooled)', 'text', '', ALL
'Subject',          'Subject ID (chinroster column 1)',                                             'text',    '',        ALL
'Sex',              'Sex from the chinroster "Sex" column (empty when not given)',                  'text',    '',        ALL
'Condition',        'Condition (time point) name, in roster order',                                  'text',    '',        ALL
'Reference',        'Empty = absolute value; else the reference condition the Value / Mean is a change from (Value = Condition - Reference)', 'text', '', ALL
'Excluded',         'true = this subject x condition is excluded from the group statistics (value kept)', 'logical', '',   ALL
'Stimulus',         'Click or Tone',                                                                'text',    '',        ABR
'Frequency_kHz',    'ABR: tone frequency (empty for click). OAE: band centre (e.g. 1.414) or region range (e.g. 0.5-2) as text', 'number (ABR) / text (OAE)', 'kHz', [ABR ';' OAE]
'Level_dBSPL',      'Stimulus level (empty for per-frequency rows such as Threshold)',               'number',  'dB SPL',  [ABR ';EFR_RAM;EFR_dAM']
'Repeat',           'Occurrence of the same frequency x level in one recording (1, 2, ... ; ABR repeated levels in "all" mode)', 'integer', '', ABR
'Wave',             'ABR wave (I-V); empty for VisualThreshold',                                     'text',    '',        'ABR_Peaks'
'Harmonic',         'Harmonic number k of the RAM modulation frequency (empty for sums)',           'integer', '',        'EFR_RAM'
'ModFrequency_Hz',  'Modulation-domain frequency (RAM: k x F0; dAM: trajectory frequency)',          'number',  'Hz',      'EFR_RAM;EFR_dAM'
'Region',           'OAE: Low / Mid / High region (empty = band row). EFR RAM: All / Low / High harmonic sum (empty = per harmonic)', 'text', '', [OAE ';EFR_RAM']
'HarmonicRange',    'Harmonics summed for the row (e.g. H1-H4; Setup EFR ranges)',                  'text',    '',        'EFR_RAM'
'Scale',            'OAE level scale: EPL (emitted pressure level) or SPL',                         'text',    '',        OAE
'Elicitor_dBFPL',   'MEMR elicitor level (empty for per-recording scalars)',                         'number',  'dB FPL',  ['MEMR;' MX]
'Metric',           'What Value measures (PascalCase id; see the Metric= rows)',                    'text',    '',        ALL
'Value',            'Measured value of Metric for one subject x condition (x keys)',                 'number',  'see Units', ALL
'Units',            'Units of Value / Mean / SD (empty = unitless or 0/1)',                         'text',    '',        ALL
'Mean',             'Group mean over the non-excluded subjects (finite values)',                     'number',  'see Units', ALL
'SD',               'Group standard deviation (0 when N = 1, empty when N = 0)',                     'number',  'see Units', ALL
'N',                'Number of subjects in Mean / SD',                                              'integer', '',        ALL
};
Mt = {
'Threshold',            'ABR threshold (fitted to the response correlation)',      'dB SPL',  'ABR_Thresholds'
'ResponseCorrelation',  'Bootstrap cross-correlation of the response at Level_dBSPL', '',     'ABR_Thresholds'
'PeakAmplitude',        'Wave peak amplitude',                                      'uV',      'ABR_Peaks'
'TroughAmplitude',      'Wave trough amplitude',                                    'uV',      'ABR_Peaks'
'PeakToPeakAmplitude',  'Peak minus trough amplitude',                              'uV',      'ABR_Peaks'
'PeakLatency',          'Wave peak latency',                                        'ms',      'ABR_Peaks'
'TroughLatency',        'Wave trough latency',                                      'ms',      'ABR_Peaks'
'VisualThreshold',      'Visual threshold of the frequency (peak picker)',          'dB SPL',  'ABR_Peaks'
'PLV',                  'Phase-locking value at the harmonic',                      '',        'EFR_RAM'
'PLVSNR',               'PLV re. neighbouring bins 5-40 Hz away',                   'dB',      'EFR_RAM'
'PLVSum',               'Sum of PLV over HarmonicRange',                            '',        'EFR_RAM'
'PLVSNRSum',            'Sum of PLVSNR over HarmonicRange (Setup measure SNR)',     'dB',      'EFR_RAM'
'Magnitude',            'Spectral magnitude of the averaged EFR envelope at the harmonic (efr_ram_mag)', 'uV', 'EFR_RAM'
'MagnitudeSum',         'Sum of Magnitude over HarmonicRange (Setup measure Magnitude)', 'uV', 'EFR_RAM'
'MagnitudeSumFraction', 'MagnitudeSum / Magnitude summed over all harmonics (Setup normalise)', 'fraction', 'EFR_RAM'
'PLVSumFraction',       'PLVSum / PLV summed over all harmonics (Setup normalise)', 'fraction','EFR_RAM'
'PLVSNRSumFraction',    'PLVSNRSum / PLVSNR summed over all harmonics (Setup normalise)', 'fraction', 'EFR_RAM'
'dAMPower',             'Band-averaged dAM response power',                         'dB',      'EFR_dAM'
'NoiseFloor',           'Noise floor (EFR dAM; OAE in the Scale units)',            'dB / dB EPL / dB SPL', ['EFR_dAM;' OAE]
'SNR',                  'Signal minus noise floor',                                 'dB',      ['EFR_dAM;' OAE]
'OAE',                  'Emission level of the band / region',                      'dB EPL / dB SPL', OAE
'MeetsSNRCriterion',    '1 = SNR meets the Setup criterion, 0 = not (mean = proportion)', '',  OAE
'ReflexMagnitude',      'MEMR reflex magnitude (growth function)',                  'dB',      'MEMR'
'ReflexThreshold',      'Acoustic reflex threshold',                                'dB FPL',  'MEMR'
'TrialsUsed',           'Trials used in the MEMR average',                          '',        'MEMR'
};
L = mx_table();
for i = 1:size(L, 1)
    Mt(end+1, :) = {L{i,2}, L{i,4}, L{i,3}, L{i,5}}; %#ok<AGROW>
end
[~, iu] = unique(Mt(:,1), 'stable');   % V / Vn appear in two views: listed once
Mt = Mt(iu, :);
for i = 1:size(Mt, 1)
    if any(strcmp(L(:,2), Mt{i,1}))
        Mt{i,4} = strjoin(unique(L(strcmp(L(:,2), Mt{i,1}), 5), 'stable'), ';');
    end
end
M2 = [strcat('Metric=', Mt(:,1)), Mt(:,2), repmat({'Metric value'}, size(Mt,1), 1), Mt(:,3), Mt(:,4)];
D = [C; M2];
T = cell2table(D, 'VariableNames', {'Column','Description','Type','Units','Measures'});
end


function [nm, un] = mx_name(k)
L = mx_table();
i = find(strcmp(L(:,1), k), 1);
if isempty(i), nm = char(k); un = ''; else, nm = L{i,2}; un = L{i,3}; end
end


function L = mx_table()
% mx_data key, Metric id, units, description, view(s)
L = {
'V',      'VectorChange',            '%',      'Vector change of the ear-canal response',          'MEMR_Vector;MEMR_Growth'
'Vn',     'VectorChangeNoiseFloor',  '%',      'Noise floor of the vector change',                 'MEMR_Vector;MEMR_Growth'
'P',      'BandPowerChange',         'dB',     'Band power change',                                'MEMR_Vector'
'thr_nf', 'NoiseFloorThreshold',     'dB FPL', 'Lowest level above the noise floor',               'MEMR_Vector'
'vart',   'VectorART',               'dB FPL', 'Vector acoustic reflex threshold',                 'MEMR_Vector'
'max',    'MaxResponse',             '%',      'Growth fit maximum',                               'MEMR_Growth'
'x0',     'Midpoint',                'dB FPL', 'Growth fit midpoint',                              'MEMR_Growth'
'slope',  'SlopeAtMidpoint',         '%/dB',   'Growth fit slope at the midpoint',                 'MEMR_Growth'
'dyn',    'Range10to90',             'dB',     'Level range from 10 to 90 % of the maximum',       'MEMR_Growth'
'auc',    'AreaAboveNoise',          '%*dB',   'Area of the growth function above the noise',      'MEMR_Growth'
'supra',  'SuprathresholdSlope',     '%/dB',   'Slope above threshold',                            'MEMR_Growth'
'bi',     'BuildUpIndex',            '',       'Reflex build-up index',                            'MEMR_Kinetics'
'tau',    'TimeConstantTopLevel',    'ms',     'Onset time constant at the top level',             'MEMR_Kinetics'
'peak',   'PeakChangeFrequency',     'kHz',    'Frequency of the largest change (top level)',      'MEMR_Spectral'
'dA_low', 'DeltaAbsorbanceLow',      '',       'Absorbance change 0.25-1 kHz',                     'MEMR_Absorbance'
'dA_mid', 'DeltaAbsorbanceMid',      '',       'Absorbance change, mid band',                      'MEMR_Absorbance'
'D',      'ProbeChange',             '%',      'Elicitor-probe change',                            'MEMR_Probe'
'N',      'ProbeNoise',              '%',      'Elicitor-probe noise',                             'MEMR_Probe'
'thr',    'ProbeThreshold',          'dB FPL', 'Elicitor-probe threshold',                         'MEMR_Probe'
'good',   'GoodClicks',              '%',      'Clicks kept after artifact rejection',             'MEMR_Quality'
'var',    'Click1TrialVariability',  '%',      'Trial-to-trial variability of click 1',            'MEMR_Quality'
'drift',  'Click1DriftReLowest',     '%',      'Click 1 change re. the lowest level',              'MEMR_Quality'
'snr',    'ClickSNR',                'ratio',  'Click signal-to-noise ratio',                      'MEMR_Quality'
'psnr',   'ProbeSNR',                'ratio',  'Probe signal-to-noise ratio',                      'MEMR_Quality'
'ntr',    'TrialsRecorded',          '',       'Trials recorded',                                  'MEMR_Quality'
};
end
