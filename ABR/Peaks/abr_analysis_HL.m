function abr_analysis_HL(command_str,parm_num)

% June 21 2020 - taken from abr_analysis4_MH_HG2 (in Hannah's
% Y:\Users\Hannah\ARO_2018_MEMR_TTS\Analysis\ABR\Development)
% moved to Y:\HeinzLabCode for HeinzLab general use (abr_analysis_HL) 

%This function computes an ABR threshold based on series of AVERAGER files.

global paramsIN abr_FIG abr_Stimuli abr_root_dir abr_data_dir hearingStatus animal data ...
    han invert abr_out_dir freq date dataFolderpath viewraw temp_view cur_data q_fldr check_files ...
    replot_check ChinCondition ChinFile ChinID date_abr
disp('in abr_analysis_HL.m')

% abr_root_dir, abr_data_dir, abr_out_dir must be set in abr_setup, and
% made global
paramsIN.abr_root_dir= abr_root_dir;

if nargin < 1
    
    get_noise;
    co=[0.0000    0.4470    0.7410;
        0.8500    0.3250    0.0980;
        0.9290    0.6940    0.1250;
        0.4940    0.1840    0.5560;
        0.4660    0.6740    0.1880;
        0.3010    0.7450    0.9330;
        0.6350    0.0780    0.1840; ];
    set(groot,'defaultAxesColorOrder',co);
    
    abr_gui_initiate; %% Makes the GUI visible
    temp_view = get(han.temp,'Value'); % should become equal to 1
    uiwait(warndlg(sprintf('\nLeft-click: Select Peak\nRight-click: Exit Selection Mode\n\nPlease, make sure to adjust left and right template limits (red box) to fit ABR waveform for accurate threshold detection'),'Peak Instructions','modal'));
    cur_data = [];

    abr_Stimuli.dir = get_directory;
    TEMPdir=dir('*ABR*.mat');
    while isempty(TEMPdir)
        beep
        uiwait(warndlg('ABR Files Cannot Be Found in Current Directory. Please, Select a New Directory','ERROR','modal'));
        abr_Stimuli.dir = get_directory;
        TEMPdir=dir('*ABR*.mat');
    end
    set(han.abr_panel,'Box','off');
    set(han.peak_panel,'Box','off');
    set(abr_FIG.dir_txt,'string',abr_Stimuli.dir,'Color',[0.4660 0.6740 0.1880]);
    
    if strcmp(get(han.abr_panel,'Box'),'off')
        paramsIN.animal= animal;
        if contains(lower(abr_Stimuli.dir), {'nh', 'pre'})
            hearingStatus = 'NH';
        elseif contains(lower(abr_Stimuli.dir), {'hi', 'pts', 'tts', 'post'})
            hearingStatus= 'HI';
        end
        paramsIN.hearingStatus= hearingStatus;
        axes(han.text_panel);
        text(0.04,0.95,['Q' num2str(paramsIN.animal)],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom')
        set(han.abr_panel,'Box','on');
    end
    %HG ADDED 9/30
    dataChinDir = pwd;
    
    
%Sets user-initiated value edit box
elseif strcmp(command_str,'stimulus')
    switch parm_num
        case 1
            calibPICs = dir('*calib*.m');
            beep
            fn = {calibPICs.name};
            [calib_idx,ok] = listdlg('Name', 'Calibration File Manager', ...
            'PromptString',{'Please, select one calibration file to use.',''},...
            'ListSize',       [300,300], ...
            'SelectionMode','single','ListString',fn);
            abr_Stimuli.cal_pic = sscanf(fn{calib_idx},'p%d_');
            set(abr_FIG.parm_txt(1),'string',calibPICs(calib_idx).name,'Interpreter','none');
            update_picnums_for_freqval(freq/1000);
        case 3
            new_value = inputdlg({'Enter ABR Waveform Left Time Limit'},...
                'Input: ABR Time Limit', [1 50]); 
            new_value = new_value{1};
            set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
            abr_Stimuli.start = str2double(new_value);
            update_picnums_for_freqval(freq/1000);
        case 4
            new_value = inputdlg({'Enter ABR Waveform Right Time Limit'},...
            'Input: ABR Time Limit', [1 50]); 
            new_value = new_value{1};
            set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
            abr_Stimuli.end = str2double(new_value);
            update_picnums_for_freqval(freq/1000);
        case 5
            if temp_view == 1
                new_value = inputdlg({'Enter ABR Template Left Time Limit'},...
                'Input: ABR Time Limit', [1 50]); 
                new_value = new_value{1};
                set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
                abr_Stimuli.start_template = str2double(new_value);
                update_picnums_for_freqval(freq/1000);
            else
                uiwait(warndlg('Template Disabled. Limits Cannot Be Changed Until Template is Activated','ERROR','modal'));
            end
        case 6
            if temp_view == 1
                new_value = inputdlg({'Enter ABR Template Right Time Limit'},...
                'Input: ABR Time Limit', [1 50]); 
                new_value = new_value{1};
                abr_Stimuli.end_template = str2double(new_value);
                set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
                update_picnums_for_freqval(freq/1000);
            else
                uiwait(warndlg('Template Disabled. Limits Cannot Be Changed Until Template is Activated','ERROR','modal'));
            end

        case 7
            new_value = inputdlg({'Enter Number of Templates'},...
            'Input: ABR Template', [1 50]); 
            new_value = new_value{1};
            abr_Stimuli.num_templates = str2double(new_value);
            set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
            update_picnums_for_freqval(freq/1000);
        case 8
            new_value = inputdlg({'Enter Maximum Sound Pressure Level (SPL)'},...
            'Input: Max ', [1 50]); 
            new_value = new_value{1};
            abr_Stimuli.maxdB2analyze= str2double(new_value);
            set(abr_FIG.parm_txt(parm_num),'string',upper(new_value));
            update_picnums_for_freqval(freq/1000);
    end
elseif strcmp(command_str,'temp')
    temp_view = get(han.temp,'Value'); % should become equal to 1
    update_picnums_for_freqval(freq/1000);

elseif strcmp(command_str,'directory')
    abr_Stimuli.dir = get_directory;
    TEMPdir=dir('*ABR*.mat');
    while isempty(TEMPdir)
        set(abr_FIG.dir_txt,'string','Select Directory','Color','r');
        beep
        uiwait(warndlg('ABR Files Cannot Be Found in Current Directory. Please, Select a New Directory','ERROR','modal'));
        abr_Stimuli.dir = get_directory;
        TEMPdir=dir('*ABR*.mat');
    end
    set(han.abr_panel,'Box','off');
    set(han.peak_panel,'Box','off');
    set(abr_FIG.dir_txt,'string',abr_Stimuli.dir,'Color',[0.4660 0.6740 0.1880]);
    
    if strcmp(get(han.abr_panel,'Box'),'off')
        paramsIN.animal= animal;
        if contains(lower(abr_Stimuli.dir), {'nh', 'pre'})
            hearingStatus = 'NH';
        elseif contains(lower(abr_Stimuli.dir), {'hi', 'pts', 'tts', 'post'})
            hearingStatus= 'HI';
        end
        paramsIN.hearingStatus= hearingStatus;
        axes(han.text_panel);
        text(0.04,0.95,['Q' num2str(paramsIN.animal)],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom')
        set(han.abr_panel,'Box','on');
    end
    
elseif strcmp(command_str,'peaks')
    clear global 'replot'
    replot_data;
    set(han.peak_panel,'Box','on');
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);

    
elseif strcmp(command_str,'process')
    clear global 'replot'
    update_picnums_for_freqval(freq/1000) %animal,hearingStatus);
    zzz2;
    set(han.peak_panel,'Box','on');
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);

elseif strcmp(command_str,'refdata')
    if strcmp(get(han.peak_panel,'Box'),'on')
        refdata;
    else
        msgbox('Load new ABR files before plotting reference data')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);

elseif strcmp(command_str,'viewraw')
    %The checkbox should only be pressed if AC data exists
    
	%Situation 1: Corrected data has been plotted, want to go back and
  	%plot raw data
   	%AC performed = araw files exist
    %///
  	%Situation 2: AC not needed
  	%AR_marker = 1 in a file
  	%Automatically check the box and do not let user to uncheck box
   	%since only raw data exists
  	%Pop-up warning to remind user that AC was not performed
    
    viewraw = get(han.viewraw,'Value'); %should become equal to 1
    zzz5;


%KEEP cbh and cbh2????  
elseif strcmp(command_str,'cbh')
    if strcmp(get(han.peak_panel,'Box'),'on')
       stop=0;
       %AR_marker=0;
       vertLineMarker = 0;
       plot_data2(stop,vertLineMarker);
    else
        msgbox('Load new ABR files before plotting reference data')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'cbh2')
    if strcmp(get(han.peak_panel,'Box'),'on')
        AVG_refdata2;
    else
        msgbox('Load new ABR files before plotting reference data')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'invert')
    invert=get(han.invert,'Value');
    clear global 'replot'
    zzz2;
    
elseif strcmp(command_str,'change_weights')
    if strcmp(get(han.peak_panel,'Box'),'on')
        change_weights;
    else
        msgbox('Load ABR files before optimizing model fit')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'peak1')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('p',1);
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'trou1')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('n',1)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'peak2')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('p',2)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'trou2')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('n',2)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'peak3')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('p',3)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'trou3')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('n',3)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'peak4')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('p',4)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'trou4')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('n',4)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'peak5')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('p',5)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);
    
elseif strcmp(command_str,'trou5')
    if strcmp(get(han.peak_panel,'Box'),'on')
        peak2('n',5)
    else
        msgbox('Select Frequency of Interest Before Marking Peaks')
    end
    set(abr_FIG.handle, 'CurrentObject', abr_FIG.push.edit);

%PRINT
elseif strcmp(command_str,'print')
    set(gcf,'PaperOrientation','portrait'); 
    if freq~=0 %HG EDITED 9/30/19
        fName= strrep(horzcat(ChinID,'_',num2str(freq), 'Hz','_',ChinFile,'_',date_abr), '-', '_');
    else
        fName= strrep(horzcat(ChinID,'_','Click','_',ChinFile,'_',date_abr), '-', '_');
    end
    
    %Save tiff figure
    if isempty(dir(abr_out_dir)) %create directory if it doesn't exis
        mkdir(abr_out_dir)
    end
    cd(abr_out_dir)
    print_out_dir = strcat(abr_out_dir,filesep,'Print');
    if ~exist(print_out_dir,'dir')
        mkdir(print_out_dir);
    end
    cd(print_out_dir)
    saveas(gcf, fName, 'tiff');
    uiwait(msgbox(sprintf('\nFilename: %s\n\nDirectory: %s',fName,print_out_dir),'ABR - PRINT SAVED','modal'));

%SAVE -- pressing push button "Save as File"
elseif strcmp(command_str,'file')
        save_file2_HG;
        data.save_chk = 1;
        replot_data;
elseif strcmp(command_str,'edit') % added by GE 15Apr2004 %NEED THIS? -HG
    
elseif strcmp(command_str,'close')
    close_msg = questdlg('Would you like to exit ABR analysis?',...
        'Exiting ABR Analysis', 'Exit', 'Cancel','I dont know');
    answer = {close_msg};
    if contains(answer, 'Exit')
        close_saving = questdlg('Would you like to save current file before exiting ABR analysis?',...
        'Exiting ABR Analysis', 'Yes', 'No','I dont know');
        answer2 = {close_saving};
        if contains(answer2,'Yes')
            save_file2_HG;
            pause(3);
            close;
        end
        exit_msg = sprintf('\nExiting ABR Analysis\n');
        waitbar(0,exit_msg);
        pause(0.5);
        waitbar(0.33,exit_msg);
        pause(0.5);
        waitbar(0.66,exit_msg);
        pause(0.5);
        closereq;
        close all;
        data.save_chk = 1;
        cd(fileparts(abr_root_dir(1:end-1)));
        exit_msg = sprintf('\nGood Bye n.n\n');
        waitbar(1,exit_msg);
        pause(1); close;
    end     
elseif strcmp(command_str,'freq_proc500')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq1k,'Value',0);
    set(abr_FIG.push.freq2k,'Value',0);
    set(abr_FIG.push.freq4k,'Value',0);
    set(abr_FIG.push.freq8k,'Value',0);
    set(abr_FIG.push.freqClick,'Value',0);
elseif strcmp(command_str,'freq_proc1k')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq500,'Value',0);
    set(abr_FIG.push.freq2k,'Value',0);
    set(abr_FIG.push.freq4k,'Value',0);
    set(abr_FIG.push.freq8k,'Value',0);
    set(abr_FIG.push.freqClick,'Value',0);
elseif strcmp(command_str,'freq_proc2k')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq1k,'Value',0);
    set(abr_FIG.push.freq500,'Value',0);
    set(abr_FIG.push.freq4k,'Value',0);
    set(abr_FIG.push.freq8k,'Value',0);
    set(abr_FIG.push.freqClick,'Value',0);
elseif strcmp(command_str,'freq_proc4k')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq1k,'Value',0);
    set(abr_FIG.push.freq2k,'Value',0);
    set(abr_FIG.push.freq500,'Value',0);
    set(abr_FIG.push.freq8k,'Value',0);
    set(abr_FIG.push.freqClick,'Value',0);
elseif strcmp(command_str,'freq_proc8k')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq1k,'Value',0);
    set(abr_FIG.push.freq2k,'Value',0);
    set(abr_FIG.push.freq4k,'Value',0);
    set(abr_FIG.push.freq500,'Value',0);
    set(abr_FIG.push.freqClick,'Value',0);
elseif strcmp(command_str,'freq_procClick')
    clear global 'replot';
    set(abr_FIG.parm_txt(9),'string','','Color',[0.4660 0.6740 0.1880]);
    update_picnums_for_freqval(parm_num) %animal,hearingStatus);
    set(abr_FIG.push.freq1k,'Value',0);
    set(abr_FIG.push.freq2k,'Value',0);
    set(abr_FIG.push.freq4k,'Value',0);
    set(abr_FIG.push.freq8k,'Value',0);
    set(abr_FIG.push.freq500,'Value',0);
end