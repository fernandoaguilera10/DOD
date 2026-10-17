function apat_timing(step, sec)
%APAT_TIMING  Append one timing row to Analysis/APAT_timing.csv.
%   apat_timing(step, seconds)  logs how long one step of a run took.
%   The analysis / subject / condition come from the run state kept by
%   apat_run_error (same folder as APAT_error_log.txt); blind runs log
%   'hidden' instead of subject and condition. Never throws.
%
%   Steps logged (analysis_run / save_view / RunButtonPushed):
%     retrieve RAW          move_files for one subject × condition
%     analysis              RAW → result file (Branch 1)
%     summary / summary + average   result → figures (Branch 3)
%     show individual / show average   Results embedding, incl. image export
%     image export          one PNG (part of the 'show' rows)
%     TOTAL                 the whole analysis (all subjects × conditions)
%
%   Off: setappdata(0, 'APAT_timing', false)
try
    if isappdata(0, 'APAT_timing') && isequal(getappdata(0, 'APAT_timing'), false), return; end
    if ~isappdata(0, 'APAT_err'), return; end
    S = getappdata(0, 'APAT_err');
    if isempty(S) || ~isfield(S, 'file') || isempty(S.file), return; end
    f = fullfile(fileparts(S.file), 'APAT_timing.csv');
    is_new = ~exist(f, 'file');
    fid = fopen(f, 'a');
    if fid < 0, return; end
    c = onCleanup(@() fclose(fid)); %#ok<NASGU>
    if is_new, fprintf(fid, 'time,analysis,subject,condition,step,seconds\n'); end
    subj = S.ctx.subject;  cond = S.ctx.condition;
    if isfield(S.ctx, 'blind') && isequal(S.ctx.blind, true), subj = 'hidden';  cond = 'hidden'; end
    fprintf(fid, '%s,%s,%s,%s,%s,%.3f\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), ... %#ok<TNOW1,DATST>
        q(S.ctx.analysis), q(subj), q(cond), q(step), sec);
catch
end
end

function s = q(s)
s = strrep(char(s), ',', ';');
end
