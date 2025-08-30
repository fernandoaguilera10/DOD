function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,Conds2Run,CondIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template)
tolerance = 20;
snap_to_localminmax = 0;
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
frame_sig = 1:length(signal);
if ~isempty(template) && all(~isnan(template))
    %[~, xi, yi] = dtw(template/max(template),signal/max(signal),tolerance);
    [~, xi, yi] = dtw(template,signal,tolerance);
    for i = 1:size(latencies_template,1)
        warp_ind_temp = find(xi==latencies_template(i,3));
        warp_ind(i) = round(mean(warp_ind_temp));
    end
    sig_inds = yi(warp_ind);
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
    peaks = signal(sig_inds)*10^2;
    latencies = t_signal(sig_inds)*10^3;
   
    % Plotting
    figure(counter);
    subplot(length(Conds2Run),1,CondIND);
    time_plot = t_signal*10^3;
    wform_plot = 10^2*signal;
    peaks_plot = 10^2*signal(sig_inds);
    template_plot = 10^2*template;
    hold on
    plot(time_plot,wform_plot,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
    for k = 1:5 % number of waves I-V
        idx = (2*k-1):(2*k);  % indices for pairs: peak + trough
        plot(time_plot(frame_sig(sig_inds(idx))),peaks_plot(idx), 'o','Color', colors(k+4,:),'MarkerFaceColor', colors(k+4,:),'MarkerSize', 8,'LineWidth', 1.5, 'DisplayName', sprintf('Wave %d', k));
    end
    set(gca,'FontSize',25); xlim([0,20]); grid on;
    plot(time_plot(frame_sig),template_plot,'--','LineWidth',3,'color',[0 0 0 0.25],'DisplayName','Template');
else
    peaks = nan(1,10);
    latencies = nan(1,10);
    % Plotting
    figure(counter);
    subplot(length(Conds2Run),1,CondIND);
    hold on
    plot(t_signal*10^3,signal*10^2,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
end
ylim(ylim_ind);
hold off
if CondIND == 1
    title_str = sprintf('ABR Peaks (DTW) | %s | %s dB SPL | %s ',freq_str,num2str(levels(level_counter)),cell2mat(subject));
    title(title_str,'FontSize', 16,'FontWeight','bold');
    set(gca,'FontSize',25); xlim([0,20]); grid on;
    legend({},'Location','northeast','Orientation','vertical','FontSize',12)
    legend boxoff; 
end
if CondIND == length(Conds2Run)
    xlabel(x_units, 'FontWeight', 'bold');
end
subtitle(sprintf('%s',condition));
grid on;
ylabel(y_units, 'FontWeight', 'bold');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.04, 0.5, 0.94]);
end