function refdata

global abr_FIG abr_out_dir freq reff

try
    d=dir([abr_out_dir 'Q365\pre\1weekPreTTS\']);
    d = d(find(strncmp('.',{d.name},1)==0)); % Only files which are not '.' nor '..'
    str = {d.name};
    [selection ok] = listdlg('Name', 'File Manager', ...
        'PromptString',   'Select a reference dataset',...
        'SelectionMode',  'single',...
        'ListSize',       [300,300], ...
        'InitialValue',    1, ...
        'ListString',      str);
    drawnow;
catch 
    msgbox('Reference data does not exist');
    set(abr_FIG.push.refdata,'enable','off'); 
    return;
end 

if (ok==0 | isempty(selection))
else
	reffile=str{selection};
	reff = load([abr_out_dir 'Q365\pre\1weekPreTTS\' reffile], 'abrs');
	
	if ismember(freq,reff.abrs.thresholds(:,1))
 		reff.abrs.thresholds(reff.abrs.thresholds(:,1)~=freq,:)=[];    
		reff.abrs.z.par(reff.abrs.z.par(:,1)~=freq,:)=[];              
		reff.abrs.z.score(reff.abrs.z.score(:,1)~=freq,:)=[];        
		reff.abrs.amp(reff.abrs.amp(:,1)~=freq,:)=[];                  
		reff.abrs.x(reff.abrs.x(:,1)~=freq,:)=[];                      
		reff.abrs.y(reff.abrs.y(:,1)~=freq,:)=[];                     
		reff.abrs.waves(reff.abrs.waves(:,1)~=freq,:)=[];              
		
		plot_data2(0,0);
		
	else
		msgbox('Reference data does not exist')
        set(abr_FIG.push.refdata,'enable','off');
    end
	
end