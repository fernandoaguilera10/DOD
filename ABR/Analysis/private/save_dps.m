function save_dps

global dp_data_dir han_dp z zanimal zdate hearingStatus

%default = strcat('chin',zanimal,'on',zdate);
default = strcat('chin',zanimal,'_',hearingStatus,'_',zdate);
filename = inputdlg('File name:','Save Data',1,default);


if ~isempty(filename)
    filename2 = char(strcat('C:\NEL\ExpData\',filename,'.mat'));
    dpoae.data=z.DpoaeData;
    
%     if day_of(filename{1}) < 733976
%         dpoae.data(:,4)=dpoae.data(:,4)-15; %Correction for flaw in early data (pre Nov 22, 2010)
%     end
    
    if exist(filename2,'file')
        save(filename2,'dpoae','-append')
        figure(22); set(gcf,'Units','normalized','Position',[0.5 0.5 0.2 0.1])
        text(0,0,'DP field added/replaced')
        axis off; pause(0.5); close(22);
        
    else
        save(filename2,'dpoae')
        figure(22); set(gcf,'Units','normalized','Position',[0.5 0.5 0.2 0.1])
        text(0,0,'New file created')
        axis off; pause(0.5); close(22);
       
    end
    clear dpoae;
    
    
end;

