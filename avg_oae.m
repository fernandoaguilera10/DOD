function [average,idx] = avg_oae(f,oae_amp,oae_nf,f_band,oae_amp_band,oae_nf_band,Chins2Run,Conds2Run,counter,colors)
avg_f{1,length(Conds2Run)} = [];
avg_amp{1,length(Conds2Run)} = [];
avg_nf{1,length(Conds2Run)} = [];
avg_oae_band{1,length(Conds2Run)} = [];
avg_nf_band{1,length(Conds2Run)} = [];
idx = ~cellfun(@isempty,oae_amp);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
for cols = 1:length(Conds2Run)
    for rows = 1:length(Chins2Run)
        % if data is present for a given timepoint, then it will be included for averaging
        if idx(rows,cols) == 1
            avg_f{1,cols} = mean([avg_f{1,cols}; f{rows, cols}],1);
            avg_amp{1,cols} = mean([avg_amp{1,cols}; oae_amp{rows, cols}],1);
            avg_nf{1,cols} = mean([avg_nf{1,cols}; oae_nf{rows, cols}],1);
            avg_oae_band{1,cols} = mean([avg_oae_band{1,cols}; oae_amp_band{rows, cols}],1);
            avg_nf_band{1,cols} = mean([avg_nf_band{1,cols}; oae_nf_band{rows, cols}],1);
            figure(counter); hold on;
            plot(f{rows, cols}, oae_amp{rows, cols}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
            %plot(f{rows, cols}, oae_nf{rows, cols}, '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
        end
    end
end
average.f = avg_f;
average.oae = avg_amp;
average.nf = avg_nf;
average.bandF = f_band;
average.bandOAE = avg_oae_band;
average.bandNF = avg_nf_band;
end