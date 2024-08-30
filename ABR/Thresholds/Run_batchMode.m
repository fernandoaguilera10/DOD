%Author (s): Andrew Sivaprakasam
%Last Updated: April, 2024
%Description: Batch process all chins pre/post ABR data.

cwd = pwd;

datapath0 = datapath;
for c = 1:length(conditions)
    condition = char(conditions(c))
    cond_dir = [datapath,condition];
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
        
%         input('Hit enter to clear plots and move on to next chin!');

    end

    datapath = datapath0;
end 

cd(cwd);