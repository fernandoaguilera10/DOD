function NoiseVector=concat_noise(DataDir)

%%
% DataDir=[pwd '\NELData\SP-2016_07_04-Q265-Baseline\'];
CurDir=pwd;
AllFreq=["500" "1000" "2000" "4000" "8000" "click"];
addpath(pwd);

%%
NoiseVector=[];
StimStart=2.5e-3;   % 6.2 SP (NEL1); 2.5 MH (NEL2)
StimEnd1=20e-3;   % 6.2 SP (NEL1); 2.5 MH (NEL2)
StimEnd2=30e-3;   % 6.2 SP (NEL1); 2.5 MH (NEL2)

%%
for freq_var=1:length(AllFreq)
    allfiles=dir([DataDir filesep 'a*' num2str(AllFreq(freq_var)) '*']);
    search_string='a%d_*';
    if isempty(allfiles)
        allfiles=dir([DataDir filesep 'p*' num2str(AllFreq(freq_var)) '*']);
        search_string(1)='p';
    end
    
    %%
    for file_var=1:length(allfiles)
        %HG ADDED 2/20/20
        if ~contains(allfiles(file_var).name,'raw')
            picNum=sscanf(allfiles(file_var).name,search_string);
            cd(DataDir);
            xx=loadPic(picNum);
            cd(CurDir);
            while iscell(xx.AD_Data.AD_Avg_V)
                xx.AD_Data.AD_Avg_V=xx.AD_Data.AD_Avg_V{1};
            end
            
            %this is a really stupid temporary fix, but have to verify
            %xx.AD_Data is sampled correctly
                
            if isfield(xx.AD_Data, 'SampleRate')    
                fs_needed = round(48828.125);
                fs_curr = round(xx.AD_Data.SampleRate);
                xx.AD_Data.AD_Avg_V = resample(xx.AD_Data.AD_Avg_V,fs_needed,fs_curr);
            end
            
            temp_snippet1=xx.AD_Data.AD_Avg_V(1:round(xx.Stimuli.RPsamprate_Hz*StimStart));
            temp_snippet2=xx.AD_Data.AD_Avg_V(round(xx.Stimuli.RPsamprate_Hz*StimEnd1):round(xx.Stimuli.RPsamprate_Hz*StimEnd2));
            
            temp_snippet=[temp_snippet1 temp_snippet2];
            temp_snippet=temp_snippet-mean(temp_snippet);
            NoiseVector=[NoiseVector,temp_snippet]; %#ok<AGROW>
        end
    end
end
