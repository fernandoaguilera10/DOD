function p = apat_paths(adir, kind, name)
%APAT_PATHS  Where APAT keeps its own files inside the Analysis folder, so
%   none of them sit loose next to the measure folders (user, Oct 17 2026).
%
%   Analysis/
%     Roster/      chinroster Excel files (*.xlsx / *.xls)
%     Logs/        APAT_error_log.txt, APAT_timing.csv,
%                  APAT_recording_choices_log.txt, APAT_blind_run_log.txt
%     Settings/    launcher_last_settings.mat, APAT_recording_choices.mat,
%                  APAT_run_checkpoint.mat, APAT_image_index.mat
%     Reference/   APAT_data_dictionary.csv
%     ABR/ EFR/ MEMR/ OAE/   results (unchanged)
%
%   d = apat_paths(adir, kind)         folder of that kind (created if missing)
%   f = apat_paths(adir, kind, name)   file in it. A file of that name still
%                                      loose in Analysis/ (older APAT) is moved
%                                      in the first time it is asked for; if
%                                      it cannot be moved (open in Excel …)
%                                      the old path is returned so it is
%                                      still read.
%   names = apat_paths(adir, 'rosters')   roster file names: Roster/*.xlsx|xls,
%                                      after moving any loose Excel file of
%                                      Analysis/ into Roster/.
%   adir  the Analysis folder (<root>/Analysis). kind: 'roster' | 'logs' |
%         'settings' | 'reference'. Never throws (returns the best path).
if nargin < 3, name = ''; end
adir = char(adir);
if strcmp(kind, 'rosters'), p = rosters(adir); return; end
switch kind
    case 'roster',    sub = 'Roster';
    case 'logs',      sub = 'Logs';
    case 'settings',  sub = 'Settings';
    case 'reference', sub = 'Reference';
    otherwise,        error('apat_paths: unknown kind %s', kind);
end
d = fullfile(adir, sub);
try
    if ~isempty(adir) && exist(adir, 'dir') == 7 && exist(d, 'dir') ~= 7, mkdir(d); end
catch
end
if isempty(name), p = d; return; end
p = fullfile(d, char(name));
old = fullfile(adir, char(name));
if exist(p, 'file') ~= 2 && exist(old, 'file') == 2
    if ~move_in(old, p), p = old; end
end
end


function names = rosters(adir)
names = {};
d = apat_paths(adir, 'roster');
try                                              % loose Excel files of older APAT → Roster/
    L = [dir(fullfile(adir, '*.xlsx')); dir(fullfile(adir, '*.xls'))];
    for k = 1:numel(L)
        n = L(k).name;
        if startsWith(n, '._') || startsWith(n, '~$') || L(k).isdir, continue; end
        if exist(fullfile(d, n), 'file') ~= 2, move_in(fullfile(adir, n), fullfile(d, n)); end
    end
catch
end
try
    L = [dir(fullfile(d, '*.xlsx')); dir(fullfile(d, '*.xls'))];
    L = L(~startsWith({L.name}, '._') & ~startsWith({L.name}, '~$'));
    names = {L.name};
    % a roster that could not be moved is still offered
    L0 = [dir(fullfile(adir, '*.xlsx')); dir(fullfile(adir, '*.xls'))];
    L0 = L0(~startsWith({L0.name}, '._') & ~startsWith({L0.name}, '~$'));
    names = unique([names, setdiff({L0.name}, names)], 'stable');
catch
end
end


function ok = move_in(src, dst)
ok = false;
try
    ok = movefile(src, dst);
catch
end
end
