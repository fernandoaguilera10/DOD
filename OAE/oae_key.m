function k = oae_key(EXPname, kind)
%OAE_KEY  apat_save_fig view key of an OAE figure: 'dp_ind', 'sf_avg', 'te_rec' …
%   kind 'ind' | 'avg' | 'rec'
switch upper(EXPname)
    case 'DPOAE', p = 'dp';
    case 'SFOAE', p = 'sf';
    case 'TEOAE', p = 'te';
    otherwise,    p = lower(EXPname);
end
k = [p '_' kind];
end
