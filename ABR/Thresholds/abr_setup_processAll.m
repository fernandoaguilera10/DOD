%Setup file for directory information (ABR threshold)
close all;
clear;

set(0,'defaultfigurerenderer','opengl')
uname = 'sivaprakasaman';

export = 1;
freqs = [500,1e3,2e3,4e3,8e3];

%Check the baseline directory for list of chins
data_dir = ['/media/',uname,'/AndrewNVME/Pitch_Study/Pitch_Diagnostics_SH_AS/ABR/Chin/'];
conditions = ["Baselines", "CA_2wksPost","TTS_2wksPost","PTS_2wksPost"];

for c = 1:length(conditions)
    condition = char(conditions(c))
    cond_dir = [data_dir,condition];
    cd(cond_dir);
    chin_list = {dir('Q*').name};
    
    for l = 1:length(chin_list)
        subj = chin_list{l};
        datapath = [cond_dir,'/',subj];

        try
            ABR_audiogram_chin;
        catch
            warning('Unable to generate audiogram. Is directory using the right file structure?')
        end
    end


end 
