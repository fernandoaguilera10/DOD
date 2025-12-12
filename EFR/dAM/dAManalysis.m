function dAManalysis(datapath,outpath,subject,condition)% EFR dAM analysis
% Author: Satya Parida
% Updated: July 2025 by Fernando Aguilera de Alba
% Purpose: Script to import/plot/apply additional processing to dAM_EFR files (chin version)
smooth_type = 'band';
noise_flag = 0; % check if including broadband noise stimuli
t_dur = 1.5; % duration of stimuli in s
flist=4000;%tone carrier in Hz
fs_stim=97656.25; %TDT sampling rate
tvec=1/fs_stim:1/fs_stim:t_dur; %time in s
tdat=tvec;
tvec2=1/fs_stim:1/fs_stim:t_dur/2; %duration of each piece. this duration is hard coded to match the number of points in tvec
tvec3=tvec2(end)+1/fs_stim:1/fs_stim:t_dur; %duration of each piece. %changed the duration such that the first segment ends near 0 amplitude so any small phase shift won't matter
aa=length(tvec);
bb=length(tvec2);
cc=length(tvec3);
rftime=.001; %rise fall time in s
rflen=round(rftime*fs_stim); %length of rise or fall
rise(1:rflen)=1-(cos(2*pi*(1/(1.33*pi*rftime))*tvec(1:rflen))).^2;
fall(1:rflen)=rise(rflen:-1:1);
tonecar=sin(2*pi*flist*tvec); %tone carrier

AMmodfq1(1:length(tvec2))=linspace(4,6.5,length(tvec2));
fq1 = 2.5; fq2 = 40; fq3 = 1200; % frequencies for pieces in Hz
%AMmodfq1(1:length(tvec2))=linspace(log2(fq1),log2(fq2),length(tvec2));
modfqdiff=0.625*(AMmodfq1(2)-AMmodfq1(1)); %the scaling is to match the step size of the second vector  
AMmodfq1(length(tvec2)+1:length(tvec))=linspace(6.5+modfqdiff,10.5,length(tvec3));
%AMmodfq1(length(tvec2)+1:length(tvec))=linspace(log2(fq2)+modfqdiff,log2(fq3),length(tvec3));
AMmoddepth1=1;
AMfreqvec=2.^AMmodfq1;
AMmod1=0.5*(1-AMmoddepth1*cos(AMfreqvec.*tvec+.001));
amfmtonevec=tonecar(1:length(tvec)).*AMmod1;

if noise_flag
    noisecar=randn(1,length(tvec)); %noise carrier
    noisecar(find(noisecar>3.5))=3.5; %remove large outliers in noise
    noisecar(find(noisecar<-3.5))=-3.5; %remove large outliers in noise
    amfmnoisevec(1:length(tvec))=noisecar.*AMmod1;
end

bp_window_Hz= [10, 1500]; %band pass filter window
Filter_HalfWindow_Hz= 12; %low pass cutoff frequency (for demodulation calculation)
tMin_s= 0;
tMax_s= t_dur;
cwd = pwd;
search_file = 'p*AMFM*4kHz*.mat';
if exist(datapath,'dir')
    cd(datapath);
    datafile = dir(fullfile(cd,search_file));
    numOfFiles = length(datafile);
    for i=1:numOfFiles
        cd(datapath)
        load(datafile(i).name);
        calibfile = dir(sprintf('p*%d_calib*.m',data.invfilterdata.CalibPICnum2use));
        calibfile = calibfile.name;
        fprintf('Calibration file: %s\n', calibfile);
        level_spl = round(data.Stimuli.calib_dBSPLout-data.Stimuli.atten_dB);
        fprintf('Data file: %s (%d dB SPL)\n', datafile(i).name,level_spl);
        fs_resp = data.Stimuli.RPsamprate_Hz;
        nMin_ind_ffr= max(1, floor(fs_resp*tMin_s));
        nMax_ind_ffr= floor(fs_resp * tMax_s);
        t_ffr= (nMin_ind_ffr:nMax_ind_ffr)/fs_resp;
        bp_filter_ffr= get_filter_designfilt('bp', bp_window_Hz, fs_resp);
        Xorg= (1:length(AMfreqvec))' / fs_stim;
        Yorg= AMfreqvec(:);
        
        % Make frequency trajectories for plotting/calculations
        dam_traj_Hz= interp1(Xorg(:), Yorg(:), t_ffr(:));
        dam_traj_Hz_NFupper= dam_traj_Hz + dam_traj_Hz(end); %noise floor frequency trajectory
        exampleEFR = mean(cell2mat(data.AD_Data.AD_All_V{1,1}'));
        exampleEFR= filtfilt(bp_filter_ffr, exampleEFR);
        exampleEFR= detrend(exampleEFR);
        cd(cwd);
        [dAM_pow_frac, dAM_pow] = get_trajectory_hilbert_signal(exampleEFR, fs_resp, dam_traj_Hz, Filter_HalfWindow_Hz);
        [dAM_powNF_frac, dAM_powNF] = get_trajectory_hilbert_signal(exampleEFR, fs_resp, dam_traj_Hz_NFupper, Filter_HalfWindow_Hz);
        dAM_pow = db(dAM_pow);
        dAM_powNF = db(dAM_powNF);
        dAM_pow_frac = db(dAM_pow_frac);
        dAM_powNF_frac = db(dAM_powNF_frac);
        nan_idx = ~isnan(dam_traj_Hz);
        dam_traj_Hz = dam_traj_Hz(nan_idx);
        dAM_pow_frac = dAM_pow_frac(nan_idx);
        dAM_powNF_frac = dAM_powNF_frac(nan_idx);
        %% Plot dAM
        blck = [0.25, 0.25, 0.25, 0.25];
        rd = [0.8500, 0.3250, 0.0980, 0.25];
        yl = [237,177,32]/255;
        gr = [0, 192, 0]/255;
        figure;
        hold on;
        title([subject,' | ', num2str(flist),' Hz dAM | ',condition, ' | ',num2str(level_spl), ' dB SPL (n = 200)'],'FontSize',14);
        plot(dam_traj_Hz,dAM_pow_frac,'Color',blck,'linewidth',3,'DisplayName','dAM');    % response
        plot(dam_traj_Hz,dAM_powNF_frac,'Color',rd,'linewidth',3,'DisplayName','NF');    % noise floor
        % Plot smoothing
        switch smooth_type
            case 'band'
                %% Smoothing: band average
                fmin = dam_traj_Hz(1);
                fmax = dam_traj_Hz(find(~isnan(dam_traj_Hz), 1, 'last')); % find last non-nan value
                edges = 2 .^ linspace(log2(fmin), log2(fmax), 36);
                bandEdges = edges(2:2:end-1);
                centerFreqs = edges(3:2:end-2)';
                dAM_w = zeros(length(centerFreqs),1);
                nf_w = zeros(length(centerFreqs),1);
                % resample / average to 9 center frequencies
                for z = 1:length(centerFreqs)
                    band = find( dam_traj_Hz >= bandEdges(z) & dam_traj_Hz < bandEdges(z+1));
                    % Do some weighting by SNR
                    SNR = dAM_pow_frac(band) - dAM_powNF_frac(band);
                    weight = (10.^(SNR./10)).^2;
                    dAM_mean(z, 1) = mean(dAM_pow_frac(band));
                    nf_mean(z,1) = mean(dAM_powNF_frac(band));
                    dAM_w(z,1) = sum(weight.*dAM_pow_frac(band))/sum(weight);
                    nf_w(z,1) = sum(weight.*dAM_powNF_frac(band))/sum(weight);
                end
                dAM_smooth = dAM_w;
                nf_smooth = nf_w;
                f_smooth = centerFreqs;
                plot(centerFreqs,dAM_smooth,'ok','linestyle','--','linewidth',3,'markersize',12,'markerfacecolor','k','HandleVisibility','off');    % response
                plot(centerFreqs,nf_smooth,'xr','linestyle','--','linewidth',3,'markersize',12,'markerfacecolor','r','HandleVisibility','off');    % noise floor
                smooth_type_string = sprintf('%s Band-Average',num2str(length(centerFreqs)));
            case 'loess'
            % Smoothing: Loess
            dAM_smooth = smooth(dam_traj_Hz,dAM_pow_frac,0.25,'loess');
            nf_smooth = smooth(dam_traj_Hz,dAM_powNF_frac,0.25,'loess');
            f_smooth = dam_traj_Hz;
            plot(dam_traj_Hz,dAM_smooth,'Color','k','linestyle','--','linewidth',3,'HandleVisibility','off');    % response
            plot(dam_traj_Hz,nf_smooth,'Color','r','linestyle','--','linewidth',3,'HandleVisibility','off');    % noise floor
            smooth_type_string = 'Loess';
        end
        subtitle(['Smoothing: ', smooth_type_string]);
        hold off;  box off; xlim([-inf,inf]);
        legend('boxoff');
        ylabel('Power (dB)','FontWeight','bold')
        xlabel('Frequency(Hz)','FontWeight','bold')
        set(gca, 'XScale', 'log')
        set(gca,'FontSize',15);
        set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
        %% Export:
        cd(outpath);
        datafile_str = datafile(i).name;
        fname = [subject,'_EFR_dAM_',condition,'_',num2str(level_spl),'dBSPL','_',datafile_str(1:end-4)];
        print(gcf,[fname,'_figure'],'-dpng','-r300');
        efr.trajectory = dam_traj_Hz;
        efr.dAMpower = dAM_pow_frac;
        efr.NFpower = dAM_powNF_frac;
        efr.spl = level_spl;
        efr.smooth.f = f_smooth;
        efr.smooth.dAM = dAM_smooth;
        efr.smooth.NF = nf_smooth;
        save(fname,'efr')
    end
    cd(cwd)
else
    fprintf('%s was not found.\n',datapath);
    return
end
end


%% Local Functions
% filtering function
function Hd= get_filter_designfilt(filtType, freqWindow, fs, filtOrder, plotYes)
if ~exist('filtOrder', 'var')
    filtOrder= 2;
end
if ~exist('plotYes', 'var')
    plotYes=0;
end

switch lower(filtType)
    case {'band', 'bandpass', 'bp'}
        Hd= designfilt('bandpassiir','FilterOrder',filtOrder, ...
            'HalfPowerFrequency1',freqWindow(1),'HalfPowerFrequency2',freqWindow(2), ...
            'SampleRate',fs);
    case {'low', 'lowpass', 'lp'}
        Hd= designfilt('lowpassiir','FilterOrder',filtOrder, ...
            'PassbandFrequency',freqWindow, 'SampleRate',fs);
    case {'high', 'highpass', 'hp'}
        Hd= designfilt('highpassiir','FilterOrder',filtOrder, ...
            'PassbandFrequency',freqWindow, 'SampleRate',fs);
end
    if plotYes
        freqz(Hd, 2^12, fs);
    end
end

% Demodulated power calculation function

%inSig=raw input signal (recording)
%fs=frequency trajectory of inSig
%freqTrajecotry= frequency trajectory of stimulus (AMfreqvec in this case)
%filtParams=low pass cutoff frequency (12 Hz)

function [fracSignal, filtSignal, sig_remod, sig_static_mod]= get_trajectory_hilbert_signal(inSig, fs, freqTrajectory, filtParams)
                                           
if nargin<3
    error('Need at least three inputs (input signal, sampling frequency, frequency trajectory along which we need to estimate power)');
end

if numel(inSig)~=numel(freqTrajectory)
    error('Length of inSig and freqTrajectory should be the same');
end

inSig= hilbert(inSig(:));
freqTrajectory= freqTrajectory(:);
freqTrajectory(isnan(freqTrajectory))= 0;
siglen= length(inSig);
stim_dur= siglen/fs;

if ~exist('filtParams', 'var')
    filtParams= 2/stim_dur;
    d_lp= designfilt('lowpassiir','FilterOrder', 2, ...
        'HalfPowerFrequency', filtParams/(fs/2), 'DesignMethod','butter');
elseif isempty(filtParams)
    filtParams= 2/stim_dur;
    d_lp= designfilt('lowpassiir','FilterOrder', 2, ...
        'HalfPowerFrequency', filtParams/(fs/2), 'DesignMethod','butter');
elseif isnumeric(filtParams)
    d_lp= designfilt('lowpassiir','FilterOrder', 2, ...
        'HalfPowerFrequency', filtParams/(fs/2), 'DesignMethod','butter');
else
    d_lp= filtParams;
end

phi_trajectory= -cumtrapz(freqTrajectory)/fs; %instantaneous phase
sig_demod_empirical= inSig .* exp(2*pi*1j*phi_trajectory); %complexe demodulated signal

filtSignal= filtfilt(d_lp, sig_demod_empirical); %lowpass filter demoduilated signal
sig_remod= real(filtSignal .* exp(-2*pi*1j*phi_trajectory));
sig_static_mod= real(filtSignal .* exp(-2*pi*1j*cumtrapz(mean(freqTrajectory))/fs));

filtSignal= abs(filtSignal); %real filtered demodulated signal
fracSignal= filtSignal / rms(inSig); %normalized unitless version of filtSignal
end