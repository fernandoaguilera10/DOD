function TEsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,shapes,colors,average_flag,conds_idx) %#ok<INUSL>
% TEOAE summary — individual figures for this subject/condition and, after the
% last pair, the group figures. Band averaging, SNR criterion, regions and
% display options come from the OAE Setup panel (oae_opts) and are applied
% here, so changing them needs no re-analysis.
% Author: Fernando Aguilera de Alba  |  Updated Oct 2026 (shared oae_summary)
oae_summary('TEOAE', '_TEOAE_', outpath, OUTdir, PRIVATEdir, Chins2Run, all_Conds2Run, ...
    ChinIND, CondIND, idx_plot_relative, shapes, colors, average_flag, conds_idx);
end
