function [peaks, latencies] = findPeaks_dtw(t_signal, signal,template,latencies_template,tolerance,snap_to_localminmax)
%FINDPEAKS_DTW Summary of this function goes here
%   Detailed explanation goes here


    if ~exist('tolerance','var')
        tolerance = 20;
    end

    if ~exist('snap_to_localminmax','var')
        snap_to_localminmax = 1;
    end
        
    [~, xi, yi] = dtw(template/max(template),signal/max(signal),tolerance);
    
    for i = 1:size(latencies_template,1)
         warp_ind_temp = find(xi==latencies_template(i,3));
         warp_ind(i) = round(mean(warp_ind_temp));
    end 
    
    sig_inds = yi(warp_ind);
    frame_sig = 1:length(signal);
    
    figure;
    hold on
    plot(signal,'LineWidth',2)
    plot(frame_sig(sig_inds), signal(sig_inds),'*k','MarkerSize',6,'LineWidth',2)
    hold off

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

    hold on
    plot(frame_sig(sig_inds), signal(sig_inds),'*r','MarkerSize',6,'LineWidth',2)
    hold off

    peaks = signal(sig_inds);
    latencies = t_signal(sig_inds);

end

