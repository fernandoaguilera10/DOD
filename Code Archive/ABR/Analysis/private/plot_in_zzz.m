%% Plotting:- abr_panel and peak_panel

function plot_in_zzz(abr_xx2,delay_of_max)

global abr_Stimuli num dt line_width abr freq spl upper_y_bound lower_y_bound padvoltage ...
    y_shift date date_abr data han animal thresh_mag ABRmag AR_marker

%% some variables for plotting abrs in abr_panel
pp_amp=zeros(1,num);
for i=1:num
    pp_amp(1,i)=max(abr(:,i))-min(abr(:,i));
end
total_volts=sum(pp_amp(1,:));
total_padvolts=0.5*total_volts;
padvoltage=total_padvolts/num/2;

y_shift=zeros(1,num);
for i=1:num-1
    y_shift(1,i)=sum(pp_amp(1,i+1:num))+padvoltage*(2*num+1-2*i)+mean(abr(:,i))-min(abr(:,i));
    lower_y_bound(1,i)=sum(pp_amp(1,i+1:num))+padvoltage*(2*num-2*i);
    upper_y_bound(1,i)=sum(pp_amp(1,i:num))+padvoltage*(2*num+2-2*i);
end
y_shift(1,num)=padvoltage+(mean(abr(:,num))-min(abr(:,num)));
lower_y_bound(1,num)=0; upper_y_bound(1,num)=2*padvoltage+pp_amp(1,num);
norm_low_bound=(lower_y_bound+padvoltage)/(total_volts+total_padvolts);

%% for plotting xcor fxns
abr_xx3=abr_xx2;
abr_xx3(abr_xx3<0)=0;
xcor_time=(0:dt:time_of_bin(length(abr_xx2)));
xcor_yscale=max(abr_xx3(:,1))/(1-norm_low_bound(1,1)-norm_low_bound(1,num));
xcor_low_bound=norm_low_bound*xcor_yscale;

%% abr_panel and peak_panel

axis(han.abr_panel,[abr_Stimuli.start abr_Stimuli.end 0 total_volts+total_padvolts]);
axis(han.peak_panel,[abr_Stimuli.start abr_Stimuli.end 0 total_volts+total_padvolts]);
set(han.abr_panel,'NextPlot','Add','XTick',abr_Stimuli.start:1:abr_Stimuli.end,'XGrid','on','YGrid','on','YTick',0:0.5:total_volts+total_padvolts,'YTickLabel',[]);
set(han.peak_panel,'XTick',abr_Stimuli.start:1:abr_Stimuli.end,'XGrid','on','YGrid','on','YTick',0:0.5:total_volts+total_padvolts,'YTickLabel',[]);

%% xcor_panel
axes(han.xcor_panel);
set(han.xcor_panel,'NextPlot','ReplaceChildren')
plot(0,0,'-w');
set(han.xcor_panel,'NextPlot','Add','Box','on','YTick',[])
axis(han.xcor_panel,[0 max(xcor_time) 0 xcor_yscale])

for i=1:num
    plot(xcor_time,abr_xx3(:,i)+xcor_low_bound(1,i),'-k',...
        [0 max(xcor_time)],[3+xcor_low_bound(1,i) 3+xcor_low_bound(1,i)],':r',...
        [0 max(xcor_time)],[xcor_low_bound(1,i)-xcor_low_bound(1,num) xcor_low_bound(1,i)-xcor_low_bound(1,num)],'-k',...
        'LineWidth',line_width)
    if data.z.score(1,i) >= 3
        axes(han.xcor_panel);
        plot(delay_of_max(1,i),data.z.score(1,i)+xcor_low_bound(1,i),'r*','LineWidth',line_width) %#ok<*LAXES>
    elseif data.z.score(1,i) < 3
        axes(han.xcor_panel);
        plot(delay_of_max(1,i),data.z.score(1,i)+xcor_low_bound(1,i),'k*','LineWidth',line_width)
    end
end

for i=1:num
    data.amp(1,i)=max(abr(bin_of_time(abr_Stimuli.start_template):bin_of_time(abr_Stimuli.end_template),i))     -       min(abr(bin_of_time(abr_Stimuli.start_template):bin_of_time(abr_Stimuli.end_template),i));
    data.amp_null(1,i)=max(abr(end-bin_of_time(abr_Stimuli.end_template-abr_Stimuli.start_template):end,i))     -       min(abr(end-bin_of_time(abr_Stimuli.end_template-abr_Stimuli.start_template):end,i));  %why?
end

ABRmag(:,1)=spl';
ABRmag(:,2)=data.amp';
ABRmag(:,3)=data.amp_null';
thresh_mag = mean(ABRmag(:,3)) + 2*std(ABRmag(:,3));
ABRmag(:,4) = thresh_mag;
ABRmag = sortrows(ABRmag,1);
yes_thresh = 0;
for index = 1:num-1
    if (ABRmag(index,2) <= thresh_mag) && (ABRmag(index+1,2) >= thresh_mag) %find points that bracket 50% hit rate
        pts = index;
        yes_thresh = 1;
    end
end

%% calculate threshold
if yes_thresh
    hi_loc  = ABRmag(pts,  1);
    lo_loc  = ABRmag(pts+1,1);
    hi_resp = ABRmag(pts,  2);
    lo_resp = ABRmag(pts+1,2);
    slope  = (thresh_mag - lo_resp) / (hi_resp - lo_resp);
    data.amp_thresh = slope * (hi_loc - lo_loc) + lo_loc;
else
    data.amp_thresh = NaN;
end

%% text panel
axes(han.text_panel);
set(han.text_panel,'NextPlot','ReplaceChildren')
plot(0,0,'-w');
set(han.text_panel,'NextPlot','Add')
if freq~=0
    text(0.24,0.9375,['Freq: ' num2str(freq) ' Hz'],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom');
else
    text(0.24,0.9375,['Click'],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom');
end
date_abr = date;
text(0.04,0.9375,['Q' num2str(animal) ' on ' char(strrep(date_abr,'_','-'))],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom');

%RESET AR_marker because new frequency button pressed
AR_marker = 0;

%AR_marker = 0;
vertLineMarker = 0;
stop=0;
plot_data2(stop,vertLineMarker);