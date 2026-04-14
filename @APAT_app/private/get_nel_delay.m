function nel_delay = get_nel_delay(ROOTdir, datapath, Chins2Run, ChinIND, all_Conds2Run, CondIND, nel_delay, nel_delay_file)
% get_nel_delay  Extract NEL acoustic delay from FPL raw calibration files.
% Called once per subject/condition from analysis_run (ABR > Peaks).
%
% Locates the most recent calib_FPL_raw.mat in the corresponding OAE data
% directory (highest p-number before the first OAE recording file), and reads:
%   x.NELdelay.delay_ms  - acoustic delay in milliseconds
%   x.MetaData.NEL       - 'NEL1' or 'NEL2'
%
% Results are accumulated into Analysis/nel_delay_data.mat:
%   nel_delay.delay_ms   [nSubjects x nTimepoints]  delay in ms  (NaN = missing)
%   nel_delay.nel        [nSubjects x nTimepoints]  1 or 2        (NaN = missing)
%   nel_delay.subjects   {nSubjects x 1}            subject IDs
%   nel_delay.timepoints {1 x nTimepoints}          e.g. 'pre/Baseline'

cwd = pwd;

% Derive OAE data path from ABR datapath (swap 'ABR' -> 'OAE')
oaepath = strrep(datapath, [filesep 'ABR' filesep], [filesep 'OAE' filesep]);


%% Find calibration file for this subject/condition
if ~exist(oaepath, 'dir')
    fprintf('  [NEL DELAY] SKIP %s (%s): OAE directory not found\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
    return
end

% Find first OAE recording file (lowest p-number)
oae_files = dir(fullfile(oaepath, 'p*_sweptDPOAE.mat'));
oae_files = [oae_files; dir(fullfile(oaepath, 'p*_sweptSFOAE.mat'))];
oae_files = [oae_files; dir(fullfile(oaepath, 'p*_TEOAE.mat'))];
oae_files = oae_files(~contains({oae_files.name}, '._'));

if isempty(oae_files)
    fprintf('  [NEL DELAY] SKIP %s (%s): no OAE data files found\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
    return
end

oae_pnums = nan(numel(oae_files), 1);
for i = 1:numel(oae_files)
    tok = regexp(oae_files(i).name, '^p(\d+)', 'tokens');
    if ~isempty(tok), oae_pnums(i) = str2double(tok{1}{1}); end
end
first_oae_pnum = min(oae_pnums);

% Find most recent calib_FPL_raw before first OAE file
raw_files = dir(fullfile(oaepath, 'p*_calib_FPL_raw.mat'));
raw_files = raw_files(~contains({raw_files.name}, '._'));

if isempty(raw_files)
    fprintf('  [NEL DELAY] SKIP %s (%s): no calib_FPL_raw files found\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
    return
end

raw_pnums = nan(numel(raw_files), 1);
for i = 1:numel(raw_files)
    tok = regexp(raw_files(i).name, '^p(\d+)', 'tokens');
    if ~isempty(tok), raw_pnums(i) = str2double(tok{1}{1}); end
end

valid = raw_pnums < first_oae_pnum;
if ~any(valid)
    fprintf('  [NEL DELAY] SKIP %s (%s): no calib_FPL_raw before first OAE (p%04d)\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND}, first_oae_pnum);
    return
end

[~, best_idx] = max(raw_pnums .* valid);
calib_file = fullfile(oaepath, raw_files(best_idx).name);

%% Load and extract fields
try
    tmp = load(calib_file, 'x');
    x   = tmp.x;
catch ME
    fprintf('  [NEL DELAY] ERROR loading %s: %s\n', calib_file, ME.message);
    return
end

if isfield(x,'NELdelay') && isfield(x.NELdelay,'delay_ms')
    nel_delay.delay_ms(ChinIND, CondIND)     = x.NELdelay.delay_ms(1);
    nel_delay.is_estimated(ChinIND, CondIND) = false;
else
    fprintf('  [NEL DELAY] WARN %s (%s): NELdelay.delay_ms not found\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
end

if isfield(x,'MetaData') && isfield(x.MetaData,'NEL')
    nel_delay.nel(ChinIND, CondIND) = str2double(x.MetaData.NEL(end));  % 'NEL1'->1, 'NEL2'->2
else
    fprintf('  [NEL DELAY] WARN %s (%s): MetaData.NEL not found\n', ...
        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
end

nel_delay.nel_confirmed(ChinIND, CondIND) = ismember(nel_delay.nel(ChinIND, CondIND), [1 2]);

clear x tmp

%% Estimate delay for entries where NEL is known but delay is NaN
for s = 1:size(nel_delay.delay_ms, 1)
    for t = 1:size(nel_delay.delay_ms, 2)
        if isnan(nel_delay.delay_ms(s,t)) && ~isnan(nel_delay.nel(s,t))
            same_nel  = nel_delay.nel == nel_delay.nel(s,t);
            known     = same_nel & ~isnan(nel_delay.delay_ms);
            if any(known(:))
                nel_delay.delay_ms(s,t)     = mean(nel_delay.delay_ms(known), 'omitnan');
                nel_delay.is_estimated(s,t) = true;
                fprintf('  [NEL DELAY] ESTIMATED delay for %s (%s): %.3f ms (NEL%d mean)\n', ...
                    nel_delay.subjects{s}, nel_delay.timepoints{t}, ...
                    nel_delay.delay_ms(s,t), nel_delay.nel(s,t));
            else
                % Empirically measured defaults (Heinz Lab, Purdue)
                if nel_delay.nel(s,t) == 1   % NEL 1
                    nel_delay.delay_ms(s,t) = 4.9;
                else                         % NEL 2
                    nel_delay.delay_ms(s,t) = 4.4;
                end
                nel_delay.is_estimated(s,t) = true;
                fprintf('  [NEL DELAY] PREDETERMINED delay for %s (%s): %.3f ms (NEL%d default)\n', ...
                    nel_delay.subjects{s}, nel_delay.timepoints{t}, ...
                    nel_delay.delay_ms(s,t), nel_delay.nel(s,t));
            end
        end
    end
end

%% Save updated matrix
save(nel_delay_file, 'nel_delay');
cd(cwd);
end
