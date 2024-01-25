function abr_artifact_rejection()

global 	dataFolderpath abr_out_dir han dimcheck freqUsed

warning('off');

%HG ADDED FUNCTIONALITY 2/5/20
%Recalculates abr waveforms by subtracting the mean of last n levels

%Plotting mean levels (already exists in abr_analysis4 code

%Assumes you're already in data directory want to look at

%Copy all files in folder for all freqs --> a files become araw
%Know you what folder in
%find all a files
%aFiles = 
%loop through those, perform AR, a = araw saving, resave as a .m file
%find freq-specific a files, do demeaning subtraction
%Loop through all a files and perform artifact rejection

%Will need to change plot_data2
%Don't need abr_AR or AR_marker anymore

%Visual check for every freq? subplot of all 8

%Review how to save a .m file

%clearvars abr_AR

%CH added code to load in a files and sort into cell 2/17/20
% cd Y:\Users\Hannah\ARO_2018_MEMR_TTS\Analysis\ABR\Development\ABR-master\Matlab_ABR\ABR_analysis\private
%just want to look at a data dir to try code for now
%cd Y:\Users\Hannah\ARO_2018_MEMR_TTS\Data\Q350\ABR\pre\1weekPreTTS\MH-2018_08_29-Q350_preTTS

a_files = {dir('a*_ABR_*.mat').name};

%Set freqs
freq = freqUsed;
           
%ASSUMPTION: assuming max of 15 levels tested for array purposes
max_levels = 15;

%Initializing number of freq values
len_freq = length(freq);

%Initializing arrays
waves = cell(max_levels, len_freq);
atten = zeros(max_levels, len_freq);
ac_data = cell(max_levels, len_freq);
r = ones(1,len_freq); %counter for rows for different freq  

%Begin looping through a files, filling in data and atten arrays accordingly
for k = 1:length(a_files)
%     run(a_files(k).name);
%     x = ans;   
    
    load(a_files{k});
    
    %If freq is click...
    if x.Stimuli.clickYes == 1
        f = 1; %col 1 is click
        %Assign to data
        waves{r(1),f} = x.AD_Data.AD_Avg_V;
        %Test if format is old or new
        if (isa(x.AD_Data.AD_Avg_V, 'double') == 0)
            waves{r(1),f} = x.AD_Data.AD_Avg_V{1};
            if (isa(x.AD_Data.AD_Avg_V{1}, 'double') == 0)
                waves{r(1),f} = x.AD_Data.AD_Avg_V{1}{1};
            end
        end
        %Assign to atten
        atten(r(1),f) = round(x.Stimuli.MaxdBSPLCalib - x.Stimuli.atten_dB);
        %Increase counter
        r(1) = r(1) + 1;
    else %all other freqs
        fr = x.Stimuli.freq_hz;
        %Check back to locate freq
        f = find(fr == freq);
        %Assign to data
        waves{r(f),f} = x.AD_Data.AD_Avg_V;
        if (isa(x.AD_Data.AD_Avg_V, 'double') == 0)
            waves{r(f),f} = x.AD_Data.AD_Avg_V{1};
            if (isa(x.AD_Data.AD_Avg_V{1}, 'double') == 0)
                waves{r(f),f} = x.AD_Data.AD_Avg_V{1}{1};
            end
        end
        %Assign to atten
        atten(r(f),f) = round(x.Stimuli.MaxdBSPLCalib - x.Stimuli.atten_dB);
        if atten(r(f),f) < 0
            atten(r(f),f) = -1; %logically shouldn't have negative atten
            uiwait(warndlg('There may be a negative attenuation. Refer to line 80 in code to fix.','Negative Atten?','modal'));
        end
        r(f) = r(f) + 1;
    end  
end

%Initialize time vector
%ASSUMPTION: All x.Stimuli.RPsamprate_Hz should be same
%Take value from last a file run in above for loop
dt=500/x.Stimuli.RPsamprate_Hz; %sampling period after oversampling (the function "bin_of_time" uses ms as input time)
len_abr = length(waves{1,1});
%Brought this in from time_of_bin function
time=(len_abr-1)*dt;
abr_time=(0:dt:time);

%Sort atten to put in order
[new_atten, ind] = sort(atten, 'descend');
new_data = cell(max_levels, len_freq);
for i = 1:len_freq
    for j = 1:max_levels
        new_data{j,i} = waves{ind(j,i),i};
    end
end

%Number of lowest levels to average
n = 3;

last_level = zeros(1,len_freq);
for i = 1:len_freq
    z = find(new_atten(:,i) == 0);
    last_level(i) = z(1);
end

% levelstoAvg = cell(n,length(freq));
%meanLevels = cell(1,len_freq);

%Make full-screen fig
figure('units','normalized','outerposition',[0 0 1 1]);
for i = 1:len_freq
    k = n;
    for j = 1:n
        %levelstoAvg{j,i} = new_data{(last(i)-(k-1)),i};
        levelstoAvg(j,:) = new_data{(last_level(i) - (k-1)),i};
        k = k - 1;
    end
    %meanLevels(i,:) = mean(levelstoAvg(:,i));
    meanLevels(i,:) = mean(levelstoAvg,1);
    
    %Pop-up figure for sanity check WITH SUBPLOTS
    subplot(3,2,i)
    freq_string = num2str(freq(i));
    if contains(freq_string,'NaN') %for click
        freq_string = 'Click';
    end
    %plot(abr_time,levelstoAvg(:,r));
    plot(abr_time,levelstoAvg);
    hold on;
    plot(abr_time,meanLevels(i,:),'k','LineWidth',2);
    title(['Freq=',freq_string],'FontSize',12); %ADD IN Hz
    xlabel('Time in ms', 'FontSize',10);
    ylabel('Amplitude in uV','FontSize',10);
    %xlim([0 30]);
    xlim([0 15]);
    hold off;
end

%Question dialog pop-up
continueButton=questdlg('Would you like to perform Artifact Correction on this dataset?','AC?','Yes','No','Cancel');
if strcmp(continueButton,'Yes')    
    %Demeaning
    %Subtract meanLevels for each freq from each waveform
    for i = 1:len_freq
        for j = 1:max_levels
            if isempty(new_data{j,i}) == 1
                continue;
            end
            
            %Subtract each waveform from meanLevels for freq
            ac_data{j,i} = new_data{j,i} - meanLevels(i,:);
        end
    end
    
    %counter for negative levels in following for loop
    count = 1;
    
    if ~exist('RAW','dir')
        mkdir('RAW');
    end
    
    %Save a file data into new araw file - first part of for loop
    %Save ac_data into original a file - second part of for loop
    for aNum = 1:length(a_files)
%         run(a_files(aNum).name);
        load(a_files{aNum});
        
        ans = x;
        
        x_araw = ans; 
        yyy = ans; %had this as x
        
        
        aname = a_files{aNum};
        movefile(aname,'RAW');

        %AS changing this to append AR instead of overwriting files...
        [~,nm,ext] = fileparts(aname);
        ar_filename = [nm,'_AR.mat'];
       
       %Save ac_data into a file
       %If freq is click...
       if yyy.Stimuli.clickYes == 1
           f = 1; %col 1 is click
       else %all other freqs
           fr = yyy.Stimuli.freq_hz;
           %Check back to locate freq
           f = find(fr == freq);
       end
       level = round(yyy.Stimuli.MaxdBSPLCalib - yyy.Stimuli.atten_dB);
       if level < 0
           level = -1; %to match convention from earlier
           %JB commented these two lines out 7/25, not sure what they are 
           %supposed to do but they were causing crashes
           %r = find(level == new_atten(:,f)); %row index in atten for current freq
           %yyy.AD_Data.AD_Avg_V = ac_data{r(count),f};
           count = count + 1; %increases counter
       else
           r = find(level == new_atten(:,f)); %row index in atten for current freq
           yyy.AD_Data.AD_Avg_V = ac_data{r(1),f};
       end

       x = yyy;
       save(ar_filename,'x');

    end
       
    %Demeaning
    %Subtract meanLevels for each freq from each waveform
%     for i = 1:len_freq
%         for j = 1:max_levels
%             %Subtract each waveform from meanLevels for freq
%             ac_data{j,i} = new_data{j,i} - meanLevels(i,:);
%         end
%     end
    
elseif strcmp(continueButton,'No') %functional
    %Check to make sure
    continueButton2=questdlg('You are saying that you do not want to perform AC on this dataset now or in the future. Are you sure?','Check','Yes','No','Cancel');
    if strcmp(continueButton2,'Yes')
        %Save AR_marker into struct of each a file
        for aNum = 1:length(a_files)
            %Load in each a file
%             run(a_files(aNum).name);
%             x_new = ans; 
            
            load(a_files{aNum});
            x_new = x;
            
            
            %Add in AR_marker to struct
            x_new.AR_marker = 1;
            %Resave a file (w/AR_marker) over current a file
            fname = a_files{aNum};

            %Copied below from gain_20000 code
            %What the hell is this doing and why??? AS COME BACK TO LATER 
            
%             [dummy1 dummy2 ext] = fileparts(fname);
%             if (strcmp(ext,'.m') ~= 1)
%                 fname = [fname '.m'];
%             end
%             fid = fopen(fname,'wt+');
%             if (fid < 0)
%                 rc = -1;
%                 return;
%             end      
%             [dirname filename] = fileparts(fname);
%             fprintf(fid,'function x = %s\n', filename);
%             %here1 = strcat(pwd,filesep,fname);
%             here1 = pwd;
            
            %Need to go into analysis folder to access mat2text
%             cd(abr_out_dir);
            %AS Commented out
% %             mat2text(x_new,fid);
%             fclose('all');
            
%             %Go back to directory of a files
%             cd(here1);
        end
      
      %FIRST GO-AROUND - data currently being processed
      %Unable "view raw data" checkbox - because AC doesnt exist
      set(han.viewraw,'Enable','off');
      dimcheck = 1;
 
    elseif strcmp(continueButton2,'No') %functional
    	%Eventually put in way to go back to first questdlg?
        %Now user must restart to change mind to Yes
        uiwait(warndlg('Please reload datset from GUI in order to perform Artifact Correction.','Next step','modal'));
    else
        strcmp(continueButton,'Cancel')
        return
        close(gcf);
    end
elseif strcmp(continueButton,'Cancel')
    return
end


%% Original code starts here
% for max_levelsABR = 1:size(abr,2)
%    abr_AR(:,max_levelsABR) = abr(:,max_levelsABR) - meanLevels(:,1); 
% end

%Now send new abr corrected data to plot_data2 to replot waterfall
close(gcf);
%stop=0;
% AR_marker = 1;
%vertLineMarker = 0;
%EDIT plot_data2
% plot_data2(stop,vertLineMarker);

end

