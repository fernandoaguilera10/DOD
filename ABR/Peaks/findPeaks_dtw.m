function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,CondIND,levels,counter,subplot_counter,colors,shapes)
%FINDPEAKS_DTW Summary of this function goes here
%   Detailed explanation goes here
tolerance = 20;
snap_to_localminmax = 0;
[~, xi, yi] = dtw(template/max(template),signal/max(signal),tolerance);
for i = 1:size(latencies_template,1)
    warp_ind_temp = find(xi==latencies_template(i,3));
    warp_ind(i) = round(mean(warp_ind_temp));
end
sig_inds = yi(warp_ind);
frame_sig = 1:length(signal);
if snap_to_localminmax
    %ASSUMPTION - order of latencies is Peak -> Negative -> Peak ->
    %Negative. This will change whether min or max is identified.
    %refining to identify nearest local max/min
    %derivative
    signal(:); %force to column
    %deriv = [signal',0]-[0,signal'];
    deriv = [signal,0]-[0,signal];
    deriv = deriv(2:end);
    %simplify by making it a slope direction instead of value
    pos = 1*(deriv>0);
    neg = -1*(deriv<0);
    slope_dir = pos+neg;
    ddir = [slope_dir,0]-[0,slope_dir];
    ddir = ddir(2:end);   
    pks = find(ddir<0);
    vals = find(ddir>0); 
    for j = 1:length(sig_inds)      
        if mod(j,2)==0 %Ns
            [~,ind] = min(abs(sig_inds(j)-vals));
            sig_inds(j) = vals(ind);
        else %Ps
            [~,ind] = min(abs(sig_inds(j)-pks));
            sig_inds(j) = pks(ind);
        end
    end 
end
figure(counter);
subplot(length(levels),1,subplot_counter);
hold on
plot(t_signal*10^3,signal*10^2,'LineWidth',2,'Color', colors(CondIND,:),'HandleVisibility','off')
plot(t_signal(frame_sig(sig_inds))*10^3, signal(sig_inds)*10^2,'xk','MarkerSize',8,'LineWidth',2)
y_units = 'Peak-to-Peak Amplitude (\muV)';
x_units = 'Time (ms)';
subtitle(sprintf('%s dB SPL',num2str(levels(subplot_counter))))
set(gca,'FontSize',15); xlim([0,20]); grid on;
ylim([-1.15,1.15]*max(abs(signal*10^2)));
%plot(frame_sig(sig_inds), signal(sig_inds),'*r','MarkerSize',6,'LineWidth',2)
plot(t_signal(frame_sig)*10^3,template*10^2,'--','LineWidth',2,'color',[0 0 0 0.25])
hold off
if subplot_counter==length(levels)
    xlabel(x_units, 'FontWeight', 'bold');
elseif subplot_counter == round(length(levels)/2)
    ylabel(y_units, 'FontWeight', 'bold');
    set(gca,'xticklabels',[]);
elseif subplot_counter == 1
    title_str = sprintf('ABR Peak Picking (DTW) | Click | %s | %s ', cell2mat(subject), condition);
    title(title_str,'FontSize', 16,'FontWeight','bold');
    legend_string = {'Peaks','Template'};
    legend(legend_string,'Location','northeast','Orientation','horizontal')
    legend boxoff; grid on;
    set(gca,'xticklabels',[]);
elseif subplot_counter ~= length(levels)
    set(gca,'xticklabels',[]);
end
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.04, 0.5, 0.94]);
peaks = signal(sig_inds)*10^2;
latencies = t_signal(sig_inds)*10^3;
end

