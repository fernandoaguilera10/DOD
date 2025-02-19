function [EXPname, EXPname2, EXPname3] = analysis_menu()
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR', 'OAE', 'MEMR'};
choice = listdlg('PromptString','Select analysis type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1
        EXPname = 'ABR';
        EXPname2 = questdlg('Select ABR analysis:', ...
                        'ABR Analysis', ...
                        'Thresholds','Peaks','Thresholds');
        EXPname3 = questdlg('Select peak picking analysis:', ...
            'ABR Peal Picking Analysis', ...
            'Manual','DTW','Manual');
                    
    case 2
        EXPname = 'EFR';
        EXPname2 = questdlg('Select EFR analysis:', ...
                        'EFR Analysis', ...
                        'AM/FM','RAM','RAM');
        EXPname3 = [];
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
        EXPname3 = [];
    case 4
        EXPname = 'MEMR';
        EXPname2 = [];
        EXPname3 = [];
    otherwise
        uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
end
end