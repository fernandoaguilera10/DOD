function [EXPname, EXPname2] = analysis_menu()
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR', 'OAE', 'MEMR'};
choice = listdlg('PromptString','Select analysis type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1
        EXPname = 'ABR';
        EXPname2 = [];
    case 2
        EXPname = 'EFR';
        EXPname2 = [];
    case 3
        EXPname = 'OAE';
        OAEanalysis_options = {'DPOAE', 'SFOAE', 'TEOAE'};
        oae_type = listdlg('PromptString','Select OAE type: ','ListString',OAEanalysis_options,'SelectionMode','single','ListSize', [100 80]);
        switch oae_type
            case 1
                EXPname2 = 'DPOAE';
            case 2
                EXPname2 = 'SFOAE';
            case 3
                EXPname2 = 'TEOAE';
            otherwise
                uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
        end
    case 4
        EXPname = 'MEMR';
        EXPname2 = [];
    otherwise
        uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
end
end