function AVG_refdata2

global AVG_reff abr_data_dir

% d=dir(['C:\NEL\ExpData\']);
% d = d(find(strncmp('.',{d.name},1)==0)); % Only files which are not '.' nor '..'
% str = {d.name};
% [selection ok] = listdlg('Name', 'File Manager', ...
%     'PromptString',   'Select a reference dataset',...
%     'SelectionMode',  'single',...
%     'ListSize',       [300,300], ...
%     'InitialValue',    1, ...
%     'ListString',      str);

drawnow;

% if isempty(AVG_reff)
    AVG_reff=struct;
    wave_AVG= load([abr_data_dir 'wave_AVG.mat'],'wave_AVG');
    temp=wave_AVG.wave_AVG;
    for n=1:size(temp,1)
        for m=1:size(temp,2)
            if ~isempty(temp{n,m})
                temp{n,m}=temp{n,m}(1:end-1);
                temp{n,m}=temp{n,m}/20000*1000000;
                temp{n,m}=resample(temp{n,m},2,1);
            end
        end
    end
            AVG_reff.abrs =temp;
            AVG_reff.SPLs=[0:10:100];
% end
plot_data2
