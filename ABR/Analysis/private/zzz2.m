function zzz2

global abr_Stimuli abr_data_dir...
	num dt line_width abr freq attn spl w upper_y_bound lower_y_bound padvoltage y_shift date...
	data noise freq_level han animal abr_time thresh_mag ABRmag invert dataFolderpath ...
    include_spl include_zscore include_w replot

pic = ParseInputPicString_V2(abr_Stimuli.abr_pic); 
num=length(pic);

clear global 'reff'
clear global 'frequency'

line_width=1;
%ExpDir=fullfile(abr_data_dir,abr_Stimuli.dir);
ExpDir = dataFolderpath;
cd(ExpDir);

%Read in the ABR waveforms
abr=[]; 
freqs=NaN*ones(1,num); 
attn=NaN*ones(1,num);
hhh=dir(sprintf('a%04d*.mat',pic(1)));
if exist(hhh.name,'file') && ~isempty(hhh)
    for i=1:num
        %why do we have a loadpic function if we aren't using it
        %everywhere!!!! - AS
        fname=dir(sprintf('a%04d*.mat',pic(i)));
        filename=fname.name; %do this better 
%         eval(['x=' filename ';'])
        load(filename,'x');
        %HG edited 10/24/19 -- all click freqs should be NaN, not 1000Hz
        if ~contains(filename,'click')
            freqs(1,i)=x.Stimuli.freq_hz;
        else
            freqs(1,i)=NaN;
        end
        %freqs(1,i)=x.Stimuli.freq_hz;
        attn(1,i)=-x.Stimuli.atten_dB;
        
        %AS
        %this is a really stupid temporary fix, but have to verify
        %xx.AD_Data is sampled correctly. Only run if needed.
        if isfield(x.AD_Data, 'SampleRate')
            fs_needed = round(48828.125);
            fs_curr = round(x.AD_Data.SampleRate);
            if (isa(x.AD_Data.AD_Avg_V, 'double') == 0)
                if (isa(x.AD_Data.AD_Avg_V{1}, 'double') == 0)
                    x.AD_Data.AD_Avg_V{1}{1} = resample(x.AD_Data.AD_Avg_V{1}{1},fs_needed,fs_curr);
                    abr(:,i)=x.AD_Data.AD_Avg_V{1}{1}(1:end-1)'-mean(x.AD_Data.AD_Avg_V{1}{1}(1:end-1)); % removes DC offset
                else
                    x.AD_Data.AD_Avg_V{1} = resample(x.AD_Data.AD_Avg_V{1},fs_needed,fs_curr);
                    abr(:,i)=x.AD_Data.AD_Avg_V{1}(1:end-1)'-mean(x.AD_Data.AD_Avg_V{1}(1:end-1)); % removes DC offset
                end
            else
                x.AD_Data.AD_Avg_V = resample(x.AD_Data.AD_Avg_V,fs_needed,fs_curr);
                abr(:,i)=x.AD_Data.AD_Avg_V(1:end-1)'-mean(x.AD_Data.AD_Avg_V(1:end-1)); % removes DC offset
            end
        else
            abr(:,i)=x.AD_Data.AD_Avg_V(1:end-1)'-mean(x.AD_Data.AD_Avg_V(1:end-1)); % removes DC offset
        end        
    end


%This section might be useful for Fernando's phase variance or if data without an a is collected? REFINE - AS   
else %WHEN DOES IT  GO INTO HERE?
    for i=1:num
        fname=dir(sprintf('p%04d*.mat',pic(i)));
        filename=fname.name(1:end-2);
        eval(['x=' filename ';'])
        %HG edited 10/24/19 -- all click freqs should be NaN, not 1000Hz
        if ~contains(filename,'click')
            freqs(1,i)=x.Stimuli.freq_hz;
        else
            freqs(1,i)=NaN;
        end
        %freqs(1,i)=x.Stimuli.freq_hz;
        
        attn(1,i)=-x.Stimuli.atten_dB;
        if iscell(x.AD_Data.AD_Avg_V)
            abr(:,i)=(x.AD_Data.AD_Avg_V{1}(1:end-1)-mean(x.AD_Data.AD_Avg_V{1}(1:end-1)))'; % removes DC offset
        else
            abr(:,i)=x.AD_Data.AD_Avg_V(1:end-1)'-mean(x.AD_Data.AD_Avg_V(1:end-1)); % removes DC offset
        end
        
    end
end
%INVERT HERE
if exist('invert', 'var')
    if invert==1
        abr=-1*abr; %if traces are inverted uncomment this.
    end
end

date1=x.General.date; date=[date1(1:2) date1(4:6) date1(8:11)];
% date=abr_Stimuli.dir(4:13);
dt=500/x.Stimuli.RPsamprate_Hz; %sampling period after oversampling

%sort abrs in order of increasing attenuation
[~, order]=sort(-attn);
abr2=abr(:,order); 
attn=attn(:,order);
freqs=freqs(:,order);

abr3=-abr2/20000*1000000;% in uV, invert to make waveforms look "normal"
% abr3=abr2/20000*1000000;% in uV, invert to make waveforms look "normal"
abr=resample(abr3,2,1); %double sampling frequency of ABRs
freq_mean=mean(freqs); freq=round(freqs(1,1)/500)*500; %round to nearest 500 Hz
abr_time=(0:dt:time_of_bin(length(abr)));

[freq_level, clickmarker] = getMaxdBSPL(abr_Stimuli.cal_pic,freq);
spl2=freq_level+attn;

%Only look at abrs below maxdBtoanalyze
ABRcounter = 1;
for splNum = 1:length(spl2)
    if spl2(splNum)<=abr_Stimuli.maxdB2analyze+2;
        spl3(ABRcounter)=spl2(splNum);
        abr_NEW(:,ABRcounter) = abr(:,splNum);
        ABRcounter = ABRcounter+1;
    end
end

%Reset global variables
abr = abr_NEW;
spl = spl3;
num = size(abr_NEW,2);

% data.threshold=NaN;
% data.z.intercept=NaN; 
% data.z.slope=NaN;
% data.z.score=NaN*ones(1,num); 
% data.amp_thresh=NaN;
% data.amp=NaN*ones(1,num);
% data.x=NaN*ones(10,num);
% data.y=NaN*ones(10,num);
% data.y_forfig=NaN*ones(10,num);
% data.amp_null=NaN*ones(1,num);
% ABRmag=NaN*ones(num,4);

%some variables for plotting abrs in abr_panel
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

%Template waveform
txcor=NaN*ones(length(abr)*2-1,abr_Stimuli.num_templates); delay=NaN*ones(1,abr_Stimuli.num_templates);
for i=1:abr_Stimuli.num_templates
	txcor(:,i)=xcorr(abr(:,i),abr(:,1));
	[~, delay1(1,i)]=max(txcor(:,i));
	delay(1,i)=(delay1(1,i)-delay1(1,1))*dt;
	template1(:,1)=abr(bin_of_time(abr_Stimuli.start_template+delay(1,i)):bin_of_time(abr_Stimuli.end_template+delay(1,i)),i);
end
template=mean(template1,2);

%Cross-correlate template with noise
null_xx=xcorr((noise/20000*1000000),template); %both waves in uV
null_xx2=null_xx(length(noise):length(noise)*2-length(template),1);
peaks=[]; count=0;
for i=2:length(null_xx2)-1
   if (null_xx2(i,1)>0) && (null_xx2(i,1)>null_xx2(i-1,1)) && (null_xx2(i,1)>null_xx2(i+1,1))
      count=count+1;
      peaks(count,1)=null_xx2(i,1);
   end
end
%peaks=findpeaks(null_xx2,'minpeakheight',0);
mean_peak=mean(peaks);
stdev_peak=std(peaks);

%Cross-correlate ABRs with template waveform
abr_xx=zeros(length(abr)*2-1,num);
for i = 1:num
        abr_xx(:,i) = xcorr(abr(:,i),template);
end
abr_xx2=(abr_xx(length(abr):length(abr)*2-length(template),:)-mean_peak)/stdev_peak; %Z score

%for plotting xcor fxns
abr_xx3=abr_xx2; abr_xx3(abr_xx3<0)=0;
xcor_time=(0:dt:time_of_bin(length(abr_xx2)));
xcor_yscale=max(abr_xx3(:,1))/(1-norm_low_bound(1,1)-norm_low_bound(1,num));
xcor_low_bound=norm_low_bound*xcor_yscale;

%This is where CH tried changing to fix thresholding problem
%Load abr data for Z score and Threshold
load_abr_data;
[abr_xx2,delay_of_max]=threshold_calc_old;

%HG added 2/3/20
plot_in_zzz(abr_xx2,delay_of_max); 

% include_spl = spl;
% include_zscore = data.z.score;
% include_w = w;

%{
%Measure the Z score of each ABR
data.z.score=NaN*ones(1,num);
bin_of_max=NaN*ones(1,num);
[data.z.score(1,1),bin_of_max(1,1)]=max(abr_xx2(:,1));
for i = 2:num
	add_attn=attn(1,i-1)-attn(1,i); exp_bin=bin_of_max(1,i-1) + bin_of_time(add_attn/40) - 1;
    [data.z.score(1,i),delay]=max(abr_xx2(exp_bin-bin_of_time(1):exp_bin+bin_of_time(1),i));
	bin_of_max(1,i)=exp_bin-bin_of_time(1)+delay-1;
end
delay_of_max=time_of_bin(bin_of_max);

%Set weights for regression analysis. Z scores below 3 have no weight.
%Weighting decreases with increasing Z score from 1 @ Z=3 to 0.1 @ max Z.
w=zeros(1,num);
for i=1:num
    w(1,i)=1-0.9*((data.z.score(1,i)-3)/(max(data.z.score(1,:))-3));
	%if data.z.score(1,i)<3
    if data.z.score(1,i)< 3.99 %HG edited to match threshold_calc_old - 2/3/20
        w(1,i)=0;
	end
end

%Weighted regression and threshold calculation
%HG ADDED 11/22/19
round_spl = round(spl);
find_spl = find(round_spl <= 60);
include_spl = spl(find_spl);
include_zscore = data.z.score(find_spl);
include_w = w(find_spl);

%X=ones(num,2);
%X(:,2)=spl';
X=ones(length(include_spl),2);
X(:,2)=include_spl';
%b=lscov3(X,data.z.score',w');
b=lscov3(X,include_zscore',include_w');
data.z.slope=b(2,1);
data.z.intercept=b(1,1);
data.threshold=(3-b(1,1))/b(2,1);
%}

%{
%abr_panel and peak_panel
axis(han.abr_panel,[abr_Stimuli.start abr_Stimuli.end 0 total_volts+total_padvolts]);
axis(han.peak_panel,[abr_Stimuli.start abr_Stimuli.end 0 total_volts+total_padvolts])
set(han.abr_panel,'NextPlot','Add','XTick',[abr_Stimuli.start:1:abr_Stimuli.end],...
	'XGrid','on','YGrid','on','YTick',[0:0.5:total_volts+total_padvolts],'YTickLabel',[])
set(han.peak_panel,'XTick',[abr_Stimuli.start:1:abr_Stimuli.end],...
	'XGrid','on','YGrid','on','YTick',[0:0.5:total_volts+total_padvolts],'YTickLabel',[])

%xcor_panel
axes(han.xcor_panel); set(han.xcor_panel,'NextPlot','ReplaceChildren')
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
        plot(delay_of_max(1,i),data.z.score(1,i)+xcor_low_bound(1,i),'r*','LineWidth',line_width)
    elseif data.z.score(1,i) < 3
        axes(han.xcor_panel); 
        plot(delay_of_max(1,i),data.z.score(1,i)+xcor_low_bound(1,i),'k*','LineWidth',line_width)
    end
end

for i=1:num
	data.amp(1,i)=max(abr(bin_of_time(abr_Stimuli.start_template):bin_of_time(abr_Stimuli.end_template),i))...
			     -min(abr(bin_of_time(abr_Stimuli.start_template):bin_of_time(abr_Stimuli.end_template),i));
	data.amp_null(1,i)=max(abr(end-bin_of_time(abr_Stimuli.end_template-abr_Stimuli.start_template):end,i))...
			     -min(abr(end-bin_of_time(abr_Stimuli.end_template-abr_Stimuli.start_template):end,i));
end

ABRmag(1:num,1)=spl'; 
%ABRmag(1:num,2)=data.amp'; 
ABRmag(1:num,2)=data.amp(:,1:num)'; 
%ABRmag(1:num,3)=data.amp_null';
ABRmag(1:num,3)=data.amp_null(:,1:num)';
%thresh_mag = mean(ABRmag(:,3)) + 2*std(ABRmag(:,3));
thresh_mag = mean(ABRmag(1:num,3)) + 2*std(ABRmag(1:num,3));
ABRmag(1:num,4) = thresh_mag;
ABRmag = sortrows(ABRmag,1);
yes_thresh = 0;
for index = 1:num-1
   if (ABRmag(index,2) <= thresh_mag) && (ABRmag(index+1,2) >= thresh_mag) %find points that bracket 50% hit rate
      pts = index;
      yes_thresh = 1;
   end
end

%calculate threshold
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

%text panel
axes(han.text_panel); set(han.text_panel,'NextPlot','ReplaceChildren')
plot(0,0,'-w'); 
set(han.text_panel,'NextPlot','Add')
if isequaln(freq,NaN)
    freq2 = 'Click';
    text(0.24,0.9375,[freq2],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom')
else
    freq2 = strcat(num2str(freq),'Hz');
    text(0.24,0.9375,['Freq: ' freq2],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom')
end 
%text(0.24,0.9375,['Freq: ' freq2],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom')
text(0.04,0.9375,['Q' num2str(animal) ' on ' char(strrep(date,'_','-'))],'FontSize',14,'horizontalalignment','left','VerticalAlignment','bottom'); 
%}

%Calls function to plot
%stop=0;
%plot_data2(stop);

if ~(clickmarker == 1)
    if freqs ~= freq_mean
        msgbox('Multiple stimulus frequencies selected!');
    end
else %specifically for click
    %if isequalnan(freqs,freq_mean)
    if (any(~isnan(freqs))) %If any freqs are NOT NaN, another freq is included
        msgbox('Mutliple stimulus frequencies selected!');
    end
end