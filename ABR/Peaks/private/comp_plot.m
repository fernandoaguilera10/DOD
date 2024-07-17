function comp_plot

%set(gcf,'DefaultAxesColorOrder',[0 0 0; 1 0 0; 0 0 1; 0 1 0; 0 1 1; 1 0 1])

global dd han_abrcomp colorr titlename numfiles

axes(han_abrcomp.text); cla;
for i=1:numfiles
	if i <=5
		text(1/6,1.1-i*0.2,['* ' dd(i).name],'Fontsize',14,'HorizontalAlignment','Center',...
			'VerticalAlignment','Middle','Color',colorr(i,:))
	elseif i >5 & i <=10
		text(0.5,1.1-(i-5)*0.2,['o ' dd(i).name],'Fontsize',14,'HorizontalAlignment','Center',...
			'VerticalAlignment','Middle','Color',colorr(i,:))
	elseif i >10 & i <=15
		text(5/6,1.1-(i-10)*0.2,['x ' dd(i).name],'Fontsize',14,'HorizontalAlignment','Center'...
			,'VerticalAlignment','Middle','Color',colorr(i,:))
	end
end
%%% Plot DPOAEs

plot(han_abrcomp.dpoae,...
	dd(1).data.dpoae.data(:,2)/1000,dd(1).data.dpoae.data(:,4),[colorr(1,:) '*-'],...
	dd(2).data.dpoae.data(:,2)/1000,dd(2).data.dpoae.data(:,4),[colorr(2,:) '*-'],...
	dd(3).data.dpoae.data(:,2)/1000,dd(3).data.dpoae.data(:,4),[colorr(3,:) '*-'],...
	dd(4).data.dpoae.data(:,2)/1000,dd(4).data.dpoae.data(:,4),[colorr(4,:) '*-'],...
	dd(5).data.dpoae.data(:,2)/1000,dd(5).data.dpoae.data(:,4),[colorr(5,:) '*-'],...
	dd(6).data.dpoae.data(:,2)/1000,dd(6).data.dpoae.data(:,4),[colorr(6,:) 'o-'],...
	dd(7).data.dpoae.data(:,2)/1000,dd(7).data.dpoae.data(:,4),[colorr(7,:) 'o-'],...
	dd(8).data.dpoae.data(:,2)/1000,dd(8).data.dpoae.data(:,4),[colorr(8,:) 'o-'],...
	dd(9).data.dpoae.data(:,2)/1000,dd(9).data.dpoae.data(:,4),[colorr(9,:) 'o-'],...
	dd(10).data.dpoae.data(:,2)/1000,dd(10).data.dpoae.data(:,4),[colorr(10,:) 'o-'],...)
	dd(11).data.dpoae.data(:,2)/1000,dd(11).data.dpoae.data(:,4),[colorr(11,:) 'x-'],...
	dd(12).data.dpoae.data(:,2)/1000,dd(12).data.dpoae.data(:,4),[colorr(12,:) 'x-'],...
	dd(13).data.dpoae.data(:,2)/1000,dd(13).data.dpoae.data(:,4),[colorr(13,:) 'x-'],...
	dd(14).data.dpoae.data(:,2)/1000,dd(14).data.dpoae.data(:,4),[colorr(14,:) 'x-'],...
	dd(15).data.dpoae.data(:,2)/1000,dd(15).data.dpoae.data(:,4),[colorr(15,:) 'x-'])


%%%Plot ABR thresholds

plot(han_abrcomp.thresh,...
	dd(1).data.abrs.thresholds(:,1)/1000,dd(1).data.abrs.thresholds(:,2),[colorr(1,:) '*-'],...
	dd(2).data.abrs.thresholds(:,1)/1000,dd(2).data.abrs.thresholds(:,2),[colorr(2,:) '*-'],...
	dd(3).data.abrs.thresholds(:,1)/1000,dd(3).data.abrs.thresholds(:,2),[colorr(3,:) '*-'],...
	dd(4).data.abrs.thresholds(:,1)/1000,dd(4).data.abrs.thresholds(:,2),[colorr(4,:) '*-'],...
	dd(5).data.abrs.thresholds(:,1)/1000,dd(5).data.abrs.thresholds(:,2),[colorr(5,:) '*-'],...
	dd(6).data.abrs.thresholds(:,1)/1000,dd(6).data.abrs.thresholds(:,2),[colorr(6,:) 'o-'],...
	dd(7).data.abrs.thresholds(:,1)/1000,dd(7).data.abrs.thresholds(:,2),[colorr(7,:) 'o-'],...
	dd(8).data.abrs.thresholds(:,1)/1000,dd(8).data.abrs.thresholds(:,2),[colorr(8,:) 'o-'],...
	dd(9).data.abrs.thresholds(:,1)/1000,dd(9).data.abrs.thresholds(:,2),[colorr(9,:) 'o-'],...
	dd(10).data.abrs.thresholds(:,1)/1000,dd(10).data.abrs.thresholds(:,2),[colorr(10,:) 'o-'],...
	dd(11).data.abrs.thresholds(:,1)/1000,dd(11).data.abrs.thresholds(:,2),[colorr(11,:) 'x-'],...
	dd(12).data.abrs.thresholds(:,1)/1000,dd(12).data.abrs.thresholds(:,2),[colorr(12,:) 'x-'],...
	dd(13).data.abrs.thresholds(:,1)/1000,dd(13).data.abrs.thresholds(:,2),[colorr(13,:) 'x-'],...
	dd(14).data.abrs.thresholds(:,1)/1000,dd(14).data.abrs.thresholds(:,2),[colorr(14,:) 'x-'],...
	dd(15).data.abrs.thresholds(:,1)/1000,dd(15).data.abrs.thresholds(:,2),[colorr(15,:) 'x-'])


%%%Plot ABR latency

%%% by sensation level

if get(han_abrcomp.latlevel,'Value')==1
	lat_by_level(han_abrcomp.lat8k,8000,12)
	lat_by_level(han_abrcomp.lat4k,4000,12)
	lat_by_level(han_abrcomp.lat2k,2000,12)
	lat_by_level(han_abrcomp.lat1k,1000,12)
	lat_by_level(han_abrcomp.lat05k,500,12)
	
	xlabel(han_abrcomp.lat2k,'Sensation Level (dB)','fontsize',14)
	set([han_abrcomp.lat8k han_abrcomp.lat4k han_abrcomp.lat2k han_abrcomp.lat1k han_abrcomp.lat05k],'Box','on','XGrid','on','Xlim',...
		[-10 75])
	
	%%% by SPL
	
elseif get(han_abrcomp.latlevel,'Value')==0
	lat_by_level(han_abrcomp.lat8k,8000,2)
	lat_by_level(han_abrcomp.lat4k,4000,2)
	lat_by_level(han_abrcomp.lat2k,2000,2)
	lat_by_level(han_abrcomp.lat1k,1000,2)
	lat_by_level(han_abrcomp.lat05k,500,2)
	
	xlabel(han_abrcomp.lat2k,'dB SPL','fontsize',14)
	set([han_abrcomp.lat8k han_abrcomp.lat4k han_abrcomp.lat2k han_abrcomp.lat1k han_abrcomp.lat05k],'Box','on','XGrid','on','Xlim',...
		[10 95])
	
end


%%% Plot ABR amplitude


if get(han_abrcomp.amplevel,'Value')==0
	amp_by_level(han_abrcomp.amp8k,8000,2)
	amp_by_level(han_abrcomp.amp4k,4000,2)
	amp_by_level(han_abrcomp.amp2k,2000,2)
	amp_by_level(han_abrcomp.amp1k,1000,2)
	amp_by_level(han_abrcomp.amp05k,500,2)
	
	
	xlabel(han_abrcomp.amp2k,'dB SPL','fontsize',14)
	set([han_abrcomp.amp8k han_abrcomp.amp4k han_abrcomp.amp2k han_abrcomp.amp1k han_abrcomp.amp05k],'Box','on','XGrid','on','Xlim',...
		[10 95])
	
	%%% by SL
	
elseif get(han_abrcomp.amplevel,'Value')==1
	amp_by_level(han_abrcomp.amp8k,8000,12)
	amp_by_level(han_abrcomp.amp4k,4000,12)
	amp_by_level(han_abrcomp.amp2k,2000,12)
	amp_by_level(han_abrcomp.amp1k,1000,12)
	amp_by_level(han_abrcomp.amp05k,500,12)
	
	xlabel(han_abrcomp.amp2k,'Sensation Level (dB)','fontsize',14)
	set([han_abrcomp.amp8k han_abrcomp.amp4k han_abrcomp.amp2k han_abrcomp.amp1k han_abrcomp.amp05k],'Box','on','XGrid','on','Xlim',...
		[-10 75])
	
end



set(han_abrcomp.thresh,'XGrid','on','YGrid','on','Xscale','log','XLim',[0.3 12],'Ylim',[0 80],'XTick',[0.25 0.5 1 2 4 8 16])
ylabel(han_abrcomp.thresh,'ABR threshold (dB SPL)','fontsize',14);
xlabel(han_abrcomp.thresh,'Frequency (kHz)','fontsize',14);

set(han_abrcomp.dpoae,'Box','on','XGrid','on','YGrid','on','YLim',[0 75],...
	'Xscale','log','XLim',[0.3 12],'XTick',[0.25 0.5 1 2 4 8 16])
ylabel(han_abrcomp.dpoae,'DP amplitude (dB SPL)','fontsize',14);
xlabel(han_abrcomp.dpoae,'DP Frequency (kHz)','fontsize',14);


ylabel(han_abrcomp.lat05k,'Wave I latency (ms)','fontsize',14);
set([han_abrcomp.lat8k han_abrcomp.lat4k han_abrcomp.lat2k han_abrcomp.lat1k han_abrcomp.lat05k],'YGrid','on','Ylim',[0.8 2.8],'Box','on','XGrid','on')

ylabel(han_abrcomp.amp05k,'Wave I amplitude (uV)','fontsize',14);
% if mean(isnan(d1.abrs.y(:,11)))==1 & mean(isnan(d2.abrs.y(:,11)))==1
set([han_abrcomp.amp8k han_abrcomp.amp4k han_abrcomp.amp2k han_abrcomp.amp1k han_abrcomp.amp05k],'YGrid','on','Ylim',...
	[0 3.0],'Box','on','XGrid','on')
% else
% 	set([han_abrcomp.amp8k han_abrcomp.amp4k han_abrcomp.amp2k han_abrcomp.amp1k han_abrcomp.amp05k],'YGrid','on','Ylim',...
% 		[0 max([d1.abrs.y(:,11)' d2.abrs.y(:,11)'])*1.05],'Box','on','XGrid','on')
%
% end
set([han_abrcomp.lat4k han_abrcomp.lat2k han_abrcomp.lat1k han_abrcomp.amp4k han_abrcomp.amp2k han_abrcomp.amp1k],'YTickLabel',[])
set([han_abrcomp.lat8k han_abrcomp.amp8k],'YAxisLocation','Right')


title(han_abrcomp.lat05k, '0.5 kHz','fontsize',14);title(han_abrcomp.lat1k, '1 kHz','fontsize',14);title(han_abrcomp.lat2k, '2 kHz','fontsize',14);
title(han_abrcomp.lat4k, '4 kHz','fontsize',14);title(han_abrcomp.lat8k, '8 kHz','fontsize',14);





