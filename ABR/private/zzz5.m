% Created by SP (26 Aug, 2016)
% Uses warped data to calculate noisefloor and threshold

function zzz5
%% Initialize
global  ThreshTypeCorrCovDist

ThreshTypeCorrCovDist=1;

load_abr_data; % Updates [abr_Stimuli abr_data_dir	num dt line_width abr freq attn spl date data freq_level abr_time ABRmag invert]    
[abr_xx2,delay_of_max]=threshold_calc_old;

% [abr_xx_SP,delay_of_max_SP]=threshold_calc_SDT_SP;

% if WarpFlag
%     threshold_calc_new;
%     disp('threshold_calc_new is running');
% end

plot_in_zzz(abr_xx2,delay_of_max); % Uses [abr_Stimuli num dt line_width abr freq spl upper_y_bound lower_y_bound padvoltage y_shift date data han animal thresh_mag ABRmag]
