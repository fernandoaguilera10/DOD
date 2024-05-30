function [EXPname, EXPname2] = analysis_menu()
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR', 'OAE', 'MEMR'};
choice = listdlg('PromptString','Select analysis type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1
        EXPname = 'ABR';
        EXPname2 = [];
        analysis_choice = 'TBD';
        summary_choice = 'abr_plotting.m';
        % Add your code for ABR processing here
    case 2
        EXPname = 'EFR';
        EXPname2 = [];
        analysis_choice = 'EFRanalysis.m';
        summary_choice = 'EFRsummary.m';
        % Add your code for EFR processing here
    case 3
        EXPname = 'OAE';
        OAEanalysis_options = {'DPOAE', 'SFOAE', 'TEOAE'};
        oae_type = listdlg('PromptString','Select OAE type: ','ListString',OAEanalysis_options,'SelectionMode','single','ListSize', [100 80]);
        switch oae_type
            case 1
                EXPname2 = 'DPOAE';
                analysis_choice = 'DPanalysis.m';
                summary_choice = 'DPsummary.m';
            case 2
                EXPname2 = 'SFOAE';
                analysis_choice = 'SFanalysis.m';
                summary_choice = 'SFsummary.m';
            case 3
                EXPname2 = 'TEOAE';
                analysis_choice = 'TEanalysis.m';
                summary_choice = 'TEsummary.m';
            otherwise
                uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
        end
    case 4
        EXPname = 'MEMR';
        EXPname2 = [];
        analysis_choice = 'WBMEMRanalysis.m';
        summary_choice = 'WBMEMRsummary.m';
    otherwise
        uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
end
end