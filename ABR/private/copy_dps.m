function copy_dps

global dp_data_dir han_dp z zanimal zdate


data2(1:4)=zdate(6:9)
if strcmp(zdate(3:5),'Jan')==1
    data2(5:6)='01';
elseif strcmp(zdate(3:5),'Feb')==1
    data2(5:6)='02';
elseif strcmp(zdate(3:5),'Mar')==1
    data2(5:6)='03';
elseif strcmp(zdate(3:5),'Apr')==1
    data2(5:6)='04';
elseif strcmp(zdate(3:5),'May')==1
    data2(5:6)='05';
elseif strcmp(zdate(3:5),'Jun')==1
    data2(5:6)='06';
elseif strcmp(zdate(3:5),'Jul')==1
    data2(5:6)='07';
elseif strcmp(zdate(3:5),'Aug')==1
    data2(5:6)='08';
elseif strcmp(zdate(3:5),'Sep')==1
    data2(5:6)='09';
elseif strcmp(zdate(3:5),'Oct')==1
    data2(5:6)='10';
elseif strcmp(zdate(3:5),'Nov')==1
    data2(5:6)='11';
elseif strcmp(zdate(3:5),'Dec')==1
    data2(5:6)='12';    
end
data2(7:8)=zdate(1:2);
    
dataOut(1,1)=str2num(zanimal{1});
dataOut(1,2)=str2num(data2);
dataOut(1,3:2+length(z.DpoaeData))=z.DpoaeData(:,4)';

clipboard('copy',dataOut);

% default = strcat('chin',zanimal,'on',zdate);
% filename = inputdlg('File name:','Save Data',1,default);
% 
% 
% if ~isempty(filename)
% 	filename2 = char(strcat('C:\NEL\ExpData\Summary\',filename,'.mat'));
% 	dpoae.data=z.DpoaeData;
% 
% 	if day_of(filename2) < 733976
% 		dpoae.data(:,4)=dpoae.data(:,4)-15; Correction for flaw in early data (pre Nov 22, 2010)
% 	end
% 	
%    if exist(filename2,'file')
% 	save(filename2,'dpoae','-append')
% else
%    save(filename2,'dpoae')
% end
% 	clear dpoae;
% 
% 	
% end;

