%function [pastPeaks] = peak2(type,id,pastPeaks)
function peak2(type,id)


%HG ADDED 2/6/20
%In order to add in vertical line 3 ms after P1


global abr_Stimuli num abr upper_y_bound lower_y_bound y_shift data abr_time ...
abr padvoltage AR_marker abr_FIG spl replot line_width freq replot_check marker ...
level_idx peak_idx exitwhile

warning off;

%Initializes marker
vertLineMarker = 0;
count_msg = 1;
x=abr_Stimuli.start;
while x >= abr_Stimuli.start && x <= abr_Stimuli.end

    %Set initial cutoff
    cutoff = 0.15;

    %Colors
    linestyles = {'--','--',':','-.'};
    colors = {'r','b'};

    %Peak 1, P2, P3, P4, P5
    colors2 = {'r','b','m','g','c'};

    %Peak
    count = 1;
    stop2 = 0;
    %assumption -- FIX - ADD in IF statements
    maxloops = 10; %correlates to count
    maxpeaks = 30; %correlates to pks
    maxtime = 30;

    if (type == 'p')
        invert = 1;
    else %type N
        invert = -1;
        type = 'n';
    end

    hold on;
    [x,y,marker] = ginput(1);
    %Marker=1 if left mouse button pressed
    %Marker=2 if middle mouse button pressed
    %Marker=3 if right mouse button pressed
    %Plot points
    ax = gca;
    if marker == 1
        msg_check = 1;
    elseif marker ~= 1
        msg_check = 0;
    end
    
    if msg_check == 1 && count_msg == 1
        exit_ax = axes('Position',[0 0 1 1]);
        axis off;
        exit_msg = text(0.75,0.97,'Right-click to Exit Peak Selection Mode','Color','r','FontSize',14,'horizontalalignment','right','VerticalAlignment','middle');
        count_msg = 2;
    end
    %Find dB SPL plot - HG added
    for i=1:num
        if y>lower_y_bound(1,i) && y<upper_y_bound(1,i)
            level_idx = i;
        end
    end

    % Check peaks selected in selected peak file
    if type == 'p'
        peak_idx = id*2-1;
    end
    if type == 'n'
        peak_idx = id*2;
    end
    replot_check = 0;
    if ~isempty(replot)
        peaks_sel = replot.abrs.x(:,3:end)';
        if ~isnan(peaks_sel(peak_idx,level_idx)) || ~isnan(data.x(peak_idx,level_idx))
            replot_check = 1;
        end
    end

    % Check if peak has been selected before in current plot or
    % peak file selected
    if isnan(data.x(peak_idx,level_idx)) && replot_check == 0 && marker == 1 
        exitwhile = 0;
    elseif ~isnan(data.x(peak_idx,level_idx)) && replot_check == 0 && marker == 1
        prompt_peak_cur = sprintf('The %s%d peak has already been selected at %d dB SPL during this session. Would you like to replace peak selection?',type, id, spl(level_idx));
        answer_peak_cur = questdlg(prompt_peak_cur,'ERROR: Multiple Peak Selection', 'Replace Selection', 'Exit', 'I dont know');
        if contains(answer_peak_cur,'Replace Selection')
            data.x(peak_idx,level_idx) = NaN;
            data.y(peak_idx,level_idx) = NaN;
            exitwhile = 0;
            stop = 1;
            cla;
            plot_data2(stop,vertLineMarker);
            cor_sel = 0;
            [x,y,marker] = ginput(1);
            while cor_sel == 0             
                if y>lower_y_bound(1,level_idx) && y<upper_y_bound(1,level_idx)
                    cor_sel = 1;
                else
                    uiwait(warndlg(sprintf('Peak was selected at a different sound level. Please, replace peak selection at %d dB SPL',spl(level_idx)),'ERROR'));
                    [x,y,marker] = ginput(1);
                end
            end
        elseif contains(answer_peak_cur,'Exit')
            exitwhile = 1;
        end
    elseif ~isnan(data.x(peak_idx,level_idx)) && replot_check == 1 && marker == 1
        prompt_peak_old = sprintf('The %s%d peak has already been selected at %d dB SPL in a previous session. Would you like to replace peak selection?',type, id, spl(level_idx));
        answer_peak_old = questdlg(prompt_peak_old,'ERROR: Multiple Peak Selection', 'Replace Selection', 'Exit', 'I dont know');
        if contains(answer_peak_old,'Replace Selection')        
            data.x(peak_idx,level_idx) = NaN;
            data.y(peak_idx,level_idx) = NaN;
            replot.abrs.x(level_idx,peak_idx+2) = NaN;
            replot.abrs.y(level_idx,peak_idx+2) = NaN;
            exitwhile = 0;
            stop = 1;
            cla;
            plot_data2(stop,vertLineMarker);
            cor_sel = 0;
            [x,y,marker] = ginput(1);
            while cor_sel == 0             
                if y>lower_y_bound(1,level_idx) && y<upper_y_bound(1,level_idx)
                    cor_sel = 1;
                else
                    uiwait(warndlg(sprintf('Peak was selected at a different sound level. Please, replace peak selection at %d dB SPL',spl(level_idx)),'ERROR'));
                    [x,y,marker] = ginput(1);
                end
            end
        elseif contains(answer_peak_cur,'Exit')
            exitwhile = 1;
        end
    elseif marker ~=1
        exitwhile = 1;
        stop2 = 1;
        delete(exit_ax);
    end



    %declare pks
    pks2 = zeros(maxloops,maxpeaks);
    time_loc = zeros(maxtime,maxpeaks);

    %Loop for user choosing peaks
    while (exitwhile == 0)
        if (x < abr_Stimuli.start || x > abr_Stimuli.end)
            stop2 = 1;
            break;
        end
        [yy, xx]=max(abr(bin_of_time(x-cutoff(count)):bin_of_time(x+cutoff(count)),level_idx)); % max abr amplitude within peak selection
        xxx=time_of_bin(xx)+time_of_bin(bin_of_time(x-cutoff(count)));  % time location of max abr within peak selection
        %Pop-up figure
        if (count == 1) %Only create figure once
            hfig = figure('Name','Selected Peaks','units','normalized','outerposition',[0.25 0.15 0.5 0.5]);
        end
        secCutoff = 1.5;
        ptofInterest = bin_of_time(xxx);
        time_cutoff1 = xxx-secCutoff;
        time_cutoff2 = xxx+secCutoff;
        bin_time_cutoff1 = bin_of_time(time_cutoff1);
        bin_time_cutoff2 = bin_of_time(time_cutoff2);
        bin_ptofInterest = ptofInterest + bin_time_cutoff1;
        start_pt = bin_time_cutoff1;
        end_pt = bin_time_cutoff2;
        abr_1 = abr(:,level_idx);
        window = abr(bin_of_time(x-cutoff(count)):bin_of_time(x+cutoff(count)),level_idx);
        bin_start(count)= find(abr_1 == window(1));
        bin_end(count)= find(abr_1 == window(end));
        confidence = 0.99;
        if (count == 1)
            bin_start_cutoff = round(bin_start(count)*confidence);
            bin_end_cutoff = round(bin_end(count)*(1/confidence));
        end
        if (count == 1) %only do once
            %Non-zoomed plot
            subplot(2,1,1);
            cutoff3 = 1.25;
            ax2 = gca;
            maxPT1 = max(abr_1(start_pt:end_pt,1));
            minPT1 = min(abr_1(start_pt:end_pt,1));
            plot1 = plot(abr_time(1,start_pt:end_pt),abr_1(start_pt:end_pt,1),'-k','LineWidth',1.5);
            hold on;
            name = strcat(type,num2str(id));
            title(name);
            ylabel('Amplitude (\muV)');
            xlabel('Time (ms)');
            axis tight;
            ylim([0.3*minPT1, 1.1*maxPT1]);
            % Zoomed plot
            subplot(2,1,2);
            ax3 = gca;
            maxPT2 = max(abr_1(bin_start_cutoff:bin_end_cutoff));
            minPT2 = min(abr_1(bin_start_cutoff:bin_end_cutoff));
            plot2 = plot(abr_time(1,bin_start_cutoff:bin_end_cutoff),abr_1(bin_start_cutoff:bin_end_cutoff),'-k','LineWidth',1.5);
            hold on;
            ylabel('Amplitude (\muV)');
            xlabel('Time (ms)');
            axis tight;
            ylim([0.3*minPT1, 1.1*maxPT1]);
            title(name);
        end

        if count > 1
            count2 = 2;
            lineapp1 = strcat(colors{count2-1},linestyles{count2-1}); %old
            lineapp2 = strcat(colors{count2},linestyles{count2}); %current
            for jj = 1:count-1
                subplot(2,1,1);
                if jj == 1 && count == 2
                    delete(ori_ll1); delete(ori_rl1);
                    delete(ori_ll2); delete(ori_rl2);
                elseif jj >= 1 && count > 2
                    delete(old_ll1); delete(old_rl1);
                    delete(old_ll2); delete(old_rl2);
                    delete(new_ll1); delete(new_rl1);
                    delete(new_ll2); delete(new_rl2);
                end
                old_ll1 = line([abr_time(bin_start(jj)), abr_time(bin_start(jj))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
                old_rl1 = line([abr_time(bin_end(jj)), abr_time(bin_end(jj))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
                subplot(2,1,2);

                old_ll2 = line([abr_time(bin_start(jj)), abr_time(bin_start(jj))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
                old_rl2 = line([abr_time(bin_end(jj)), abr_time(bin_end(jj))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
            end
            subplot(2,1,1);
            new_ll1 = line([abr_time(bin_start(count)), abr_time(bin_start(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2-1},'LineStyle',linestyles{count2-1},'LineWidth',1);
            new_rl1 = line([abr_time(bin_end(count)), abr_time(bin_end(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2-1},'LineStyle',linestyles{count2-1},'LineWidth',1);
            subplot(2,1,2);
            new_ll2 = line([abr_time(bin_start(count)), abr_time(bin_start(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2-1},'LineStyle',linestyles{count2-1},'LineWidth',1);
            new_rl2 = line([abr_time(bin_end(count)), abr_time(bin_end(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2-1},'LineStyle',linestyles{count2-1},'LineWidth',1);
        else %first time through
            count2 = 1;
            lineapp1 = strcat(colors{count2},linestyles{count2}); %current
            subplot(2,1,1);
            ori_ll1 = line([abr_time(bin_start(count)), abr_time(bin_start(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
            ori_rl1 = line([abr_time(bin_end(count)), abr_time(bin_end(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
            line([x, x],[0.3*minPT1, 1.1*maxPT1],'Color','b','LineStyle',':','LineWidth',1);
            subplot(2,1,2);
            ori_ll2 = line([abr_time(bin_start(count)), abr_time(bin_start(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
            ori_rl2 = line([abr_time(bin_end(count)), abr_time(bin_end(count))],[0.3*minPT1, 1.1*maxPT1],'Color',colors{count2},'LineStyle',linestyles{count2},'LineWidth',1);
            line([x, x],[0.3*minPT1, 1.1*maxPT1],'Color','b','LineStyle',':','LineWidth',1);
        end
        %Find peaks in window
        yWindow1 = abr_1(bin_start(count):bin_end(count));
        yWindow = yWindow1*invert;
        minpeakdis = 10;
        [pks,loc] = findpeaks(yWindow,'MinPeakDistance',minpeakdis);
        %First, check to make sure peaks exist at all
        if (length(pks) < 1)
            %CH made error box more interactive
            answer6 = questdlg('No peaks found. Would you like to repeat peak selection?',...
                'No peaks found', 'Repeat', 'Exit', 'Manually enter peak', 'I dont know');
            answer = {answer6};
            if contains(answer, 'Repeat')
                stop2 = 1; %allows code to go back to main while loop
                close(hfig);
                break;
            elseif contains(answer, 'Manually enter peak')
                firstpart3 = strcat('Enter peak time:');
                prompt3 = strcat(firstpart3);
                answer6 = inputdlg(prompt3,'Manual peak selection');
                peakTime = str2double(cell2mat(answer6));
                xdata=get(plot1,'Xdata');
                ydata=get(plot1,'Ydata');
                closest = 0;
                mindiff = 100;
                for c = 1:length(xdata)
                    diff = abs(peakTime-xdata(c));
                    if diff < mindiff
                        mindiff = diff;
                        closest = c;
                    end
                end
                x11 = abr_time(bin_of_time(peakTime));
                y11 = ydata(closest);
                subplot(2,1,1);
                plot(ax2,x11,y11,'g*','LineWidth',2,'MarkerSize',5);
                subplot(2,1,2);
                plot(ax3,x11,y11,'g*','LineWidth',2,'MarkerSize',5);
                answer3 = questdlg('Do you agree with the chosen peak in green?','Yes/No?','Yes','No','I dont know');
                answer = {answer3};
                warning('off','all');
                if contains(answer,'Yes')
                    exitwhile = 1;
                    close(hfig);
                    break;
                elseif contains(answer,'No')
                    exitwhile = 0;
                end
            end
        else %at least one peak found
            if (invert == -1)
                pks = pks*-1;
            end
            pks2(count,1:length(pks')) = pks';
            time_loc_2 = time_of_bin(loc)+abr_time(bin_start(count));
            time_loc(count,1:length(loc')) = time_loc_2;
            if count > 1
                if ((sum(pks2(count-1,:)) - sum(pks2(count,:))) ~= 0) %only change if peaks are different from last time
                    for hh=1:(count-1)
                        len_hh = nnz(pks2(hh,:));
                        subplot(2,1,1);
                        plot(ax2,time_loc(hh,1:len_hh),pks2(hh,1:len_hh),'r*','LineWidth',2,'MarkerSize',5);
                        subplot(2,1,2);
                        plot(ax3,time_loc(hh,1:len_hh),pks2(hh,1:len_hh),'r*','LineWidth',2,'MarkerSize',5);
                    end
                end
                len_hh_2 = nnz(pks2(count,:));
                subplot(2,1,1);
                plot(ax2,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                subplot(2,1,2);
                plot(ax3,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
            else %first time through
                len_hh_2 = nnz(pks2(count,:));
                subplot(2,1,1);
                plot(ax2,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                subplot(2,1,2);
                plot(ax3,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
            end
            if (length(pks) > 1) %if more than one peak exists
                %Max peak becomes chosen peak
                if (invert == 1) %Peak
                    chosenPeak_sub = max(pks2(count,1:len_hh_2));
                else %Trough
                    chosenPeak_sub = min(pks2(count,1:len_hh_2));
                end
                chosenPeak_index = find(pks2(count,1:len_hh_2) == chosenPeak_sub);
                %Same
                chosenPeak(count) = pks(chosenPeak_index);
                time_xx(count) = time_loc(count,chosenPeak_index);
            else
                chosenPeak(count) = pks;
                time_xx(count) = time_loc(1,1);
            end
            if count > 1
                subplot(2,1,1);
                plot(ax2,time_xx(1:count-1),chosenPeak(1:count-1),'b*','LineWidth',2,'MarkerSize',5);
                plot(ax2,time_xx(count),chosenPeak(count),'g*','LineWidth',2,'MarkerSize',5);
                subplot(2,1,2);
                plot(ax3,time_xx(1:count-1),chosenPeak(1:count-1),'b*','LineWidth',2,'MarkerSize',5);
                plot(ax3,time_xx(count),chosenPeak(count),'g*','LineWidth',2,'MarkerSize',5);
            else %first time through
                subplot(2,1,1);
                plot(ax2,time_xx(count),chosenPeak(count),'g*','LineWidth',2,'MarkerSize',5);
                subplot(2,1,2);
                plot(ax3,time_xx(count),chosenPeak(count),'g*','LineWidth',2,'MarkerSize',5);
            end
        end

        %Question dialog box
        answer3 = questdlg('Do you agree with the chosen peak in green?','Yes/No?','Yes','No','I dont know');
        answer = {answer3};
        warning('off','all');
        if contains(answer,'Yes')
            x11 = time_xx(count);
            y11 = chosenPeak(count);
            exitwhile = 1;
            break;
        elseif contains(answer,'No')
            answer4 = questdlg('Would you like to:','Next Step','User choose peak','Change cutoff','Cancel','I dont know');
            if contains(answer4,'Change cutoff')
                %Option 1: Lower cutoff value
                firstpart = strcat('The  current cutoff is',{' '},'+/- ', num2str(cutoff(count,1)),'ms.');
                prompt = strcat(firstpart,{' '},'Enter a lower cutoff value:');
                answer2 = inputdlg(prompt,'Change cutoff');
                count = count+1;
                cutoff(count,1) = str2double(answer2);
                exitwhile = 0;
            elseif contains(answer4, 'Cancel')
                stop2 = 1; %allows code to go back to main while loop
                close(hfig);
                break;

            elseif contains(answer4, 'User choose peak')
                %First number peaks from left to right
                answer7 = questdlg('Would you like to:','Peak Selection Type','Pick preset peak','Manually enter peak','Cancel','I dont know');
                if contains(answer7,'Pick preset peak')
                    for ww = 1:length(pks)
                        xloc2 = time_loc(count,ww);
                        yloc2 = pks(ww)+0.12;
                        text(ax3,xloc2,yloc2,num2str(ww),'FontSize',15,'HorizontalAlignment','center','FontWeight','bold');
                    end
                    %User inputs peak number
                    firstpart2 = strcat('What point do you want to choose as the peak?');
                    prompt2 = strcat(firstpart2);
                    answer5 = inputdlg(prompt2,'Choose peak');
                    numberPeak = str2num(cell2mat(answer5));
                    if (numberPeak <= length(pks)) %inputted peak must be one of the peaks
                        x11 = time_loc(count,numberPeak);
                        y11 = pks(numberPeak);
                        exitwhile = 1;
                    end
                elseif contains(answer7, 'Manually enter peak')
                    firstpart3 = strcat('Enter peak time:');
                    prompt3 = strcat(firstpart3);
                    answer6 = inputdlg(prompt3,'Manual peak selection');
                    peakTime = str2double(cell2mat(answer6));
                    xdata=get(plot1,'Xdata');
                    ydata=get(plot1,'Ydata');
                    closest = 0;
                    mindiff = 100;
                    for c = 1:length(xdata)
                        diff = abs(peakTime-xdata(c));
                        if diff < mindiff
                            mindiff = diff;
                            closest = c;
                        end
                    end
                    x11 = abr_time(bin_of_time(peakTime));
                    y11 = ydata(closest);
                    subplot(2,1,1);
                    plot(ax2,x11,y11,'g*','LineWidth',2,'MarkerSize',5);
                    subplot(2,1,2);
                    plot(ax3,x11,y11,'g*','LineWidth',2,'MarkerSize',5);

                    if (invert == -1)
                        pks = pks*-1;
                    end
                    pks2(count,1:length(pks')) = pks';
                    time_loc_2 = time_of_bin(loc)+abr_time(bin_start(count));
                    time_loc(count,1:length(loc')) = time_loc_2;
                    if count > 1
                        if ((sum(pks2(count-1,:)) - sum(pks2(count,:))) ~= 0) %only change if peaks are different from last time
                            for hh=1:(count-1)
                                len_hh = nnz(pks2(hh,:));
                                subplot(2,1,1);
                                plot(ax2,time_loc(hh,1:len_hh),pks2(hh,1:len_hh),'r*','LineWidth',2,'MarkerSize',5);
                                subplot(2,1,2);
                                plot(ax3,time_loc(hh,1:len_hh),pks2(hh,1:len_hh),'r*','LineWidth',2,'MarkerSize',5);
                            end
                        end
                        len_hh_2 = nnz(pks2(count,:));
                        subplot(2,1,1);
                        plot(ax2,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                        subplot(2,1,2);
                        plot(ax3,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                    else %first time through
                        len_hh_2 = nnz(pks2(count,:));
                        subplot(2,1,1);
                        plot(ax2,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                        subplot(2,1,2);
                        plot(ax3,time_loc(count,1:len_hh_2),pks2(count,1:len_hh_2),'r*','LineWidth',2,'MarkerSize',5);
                    end
                    answer3 = questdlg('Do you agree with the chosen peak in green?','Yes/No?','Yes','No','I dont know');
                    answer = {answer3};
                    warning('off','all');
                    if contains(answer,'Yes')
                        exitwhile = 1;
                        close(hfig);
                        break;
                    elseif contains(answer,'No')
                        exitwhile = 0;
                    end

                elseif contains(answer7, 'Cancel')
                    stop2 = 1; %allows code to go back to main while loop
                    close(hfig);
                    break;
                end
            elseif contains(answer4, 'Cancel')
                stop2 = 1; %allows code to go back to main while loop
                close(hfig);
                break;
            else
                warndlg('Potential problem with code.');
            end
        else
            warndlg('Potential problem with code.');
        end
    end
axes(ax);
    if stop2 == 0
        if marker==1

            if invert == 1 %P
                data.x(id*2-1,level_idx)=x11;
                data.y(id*2-1,level_idx)=y11;
                data.y_forfig(id*2-1,level_idx)=y11+y_shift(1,level_idx);
                plot_yy = data.y_forfig(id*2-1,level_idx);
            else %N
                data.x(id*2,level_idx)=x11;
                data.y(id*2,level_idx)=y11;
                data.y_forfig(id*2,level_idx)=y11+y_shift(1,level_idx);
                plot_yy = data.y_forfig(id*2,level_idx);
            end

            if (type == 'p') && (id == 1)
                if ((nnz(~isnan(data.x))) >= 3)
                    %Basis is average of P1 for top 3 levels
                    kk = ~isnan(data.x);
                    avgLine = mean(data.x(kk));
                    vertLineMarker = avgLine;
                end
            end
            if ~isempty(replot)
                replot.abrs.x(level_idx,peak_idx+2) = data.x(peak_idx,level_idx);
                replot.abrs.y(level_idx,peak_idx+2) = data.y(peak_idx,level_idx);
                data.y_forfig =  replot.abrs.y(:,3:end)' + y_shift;
            end
            %Close peak fig
            close(hfig);
            %Plots optimized peak
            colorPT = strcat(colors2{id},'*');
            plot(ax,x11,plot_yy,colorPT,'LineWidth',1); %line that plots point, needs axes, x coord, y coord, and color.

            %Remember: colors2 = {'r','b','m','g','c'};
            if (invert == 1) %PEAK - place above peak
                text(ax,x11,plot_yy+0.05,name,'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',10,'Color',colors2{id});
            else %TROUGH - place below peak
                text(ax,x11,plot_yy-0.05,name,'HorizontalAlignment','center','VerticalAlignment','top','fontsize',10,'Color',colors2{id});
            end

        else
            %elseif marker==3
            warndlg('Use left mouse button ONLY to choose peaks! Repeat to save data.')
        end
    end
end
% Save current session data
cur_data = data;
cur_data.freq = freq;
%Call plot data function and disable buttons
stop=1;
set(abr_FIG.push.peak1,'Value',0);
set(abr_FIG.push.trou1,'Value',0);
set(abr_FIG.push.peak2,'Value',0);
set(abr_FIG.push.trou2,'Value',0);
set(abr_FIG.push.peak3,'Value',0);
set(abr_FIG.push.trou3,'Value',0);
set(abr_FIG.push.peak4,'Value',0);
set(abr_FIG.push.trou4,'Value',0);
set(abr_FIG.push.peak5,'Value',0);
set(abr_FIG.push.trou5,'Value',0);
%AR_marker = 0;
plot_data2(stop,vertLineMarker);
end