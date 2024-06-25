function loaddp

global dp_data_dir han_dp z zanimal zdate hearingStatus

%clear 'global' 'd1' 'd2' 'd3'

d=dir(dp_data_dir);
d = d(find(strncmp('.',{d.name},1)==0)); % Only files which are not '.' nor '..'
str = {d.name};
[selection ok] = listdlg('Name', 'File Manager', ...
    'PromptString',   'Select data directory',...
    'SelectionMode',  'single',...
    'ListSize',       [300,300], ...
    'InitialValue',    1, ...
    'ListString',      str);
drawnow;
dir1=str{selection(1,1)};


cd([dp_data_dir dir1])
dp_pics=dir('*dpoae*');
str = {dp_pics.name};
[selection ok] = listdlg('Name', 'File Manager', ...
    'PromptString',   'Select dp file',...
    'SelectionMode',  'single',...
    'ListSize',       [300,300], ...
    'InitialValue',    1, ...
    'ListString',      str);
drawnow;

if ok ~= 0 & length(selection)==1
    has_chin = [strfind(dir1,'chin') strfind(dir1,'Chin')];
    if ~isempty(has_chin)
        suggestedID={dir1(has_chin+(4:7))};
    else
        suggestedID={['']};
    end
    zanimal = inputdlg('Animal ID number:','',1,suggestedID);
    hearingStatus = inputdlg('Hearing status (HI/NH):','',1);
    %zanimal = inputdlg('Animal ID number:','',1);
    dp_pic=str{selection(1,1)};
    dp_pic=dp_pic(1:end-2);
    eval(['z=' dp_pic ';'])
    
    %zdate=regexprep(z.General.date,'-','');
    zdate=dir1(4:13);
    date2=str2num([zdate(1:4) zdate(6:7) zdate(9:10)]);
    if date2 < 20101122
        z.DpoaeData(:,4)=z.DpoaeData(:,4)-15;
        z.DpoaeSpectra=z.DpoaeSpectra-15;
    end
    z.DpoaeData(:,3)=2*z.DpoaeData(:,1)-z.DpoaeData(:,2);
    plot(han_dp.dp_curve,z.DpoaeData(:,3),z.DpoaeData(:,4),'*k-')
    title(han_dp.dp_curve,['Chin' char(zanimal) ' on ' char(strrep(zdate,'_','-')) ' ' hearingStatus],'FontSize',14)
    ylabel(han_dp.dp_curve,'DP amplitude (dB SPL)','fontsize',14)
    xlabel(han_dp.dp_curve,'DP frequency (Hz)','fontsize',14)
    set(han_dp.dp_curve,'Box','on','XGrid','on','YGrid','on','Xscale','log','Xlim',[300 12000],...
        'XTick',[300 400 500 600 800 1000 2000 3000 4000 5000 6000 8000 10000],'YLim',[0 100])
    
    
end
