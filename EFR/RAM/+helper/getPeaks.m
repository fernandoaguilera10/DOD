function [PKS,LOCS] = getPeaks(f,DFT,F0,harmonics)
%getSum Outputs the sum of first 5 harmonics of a given .
%deviation. Also makes a plot.
%f = frequency vector
%DFT = DFT.
%F0 = fundamental freq
%harmonics = number of harmonics to pull 

% [PKS, LOCS] = findpeaks(DFT,f,'MinPeakHeight',max(DFT)/3,'MinPeakDistance',80);
% PKS = PKS.*(LOCS>99);
% LOCS = LOCS(1:harmonics);
% 

%%harms = F0:F0:harmonics*F0;
PKS = zeros(1,harmonics);
LOCS = zeros(1,harmonics);

for i=1:harmonics
    
    %figure out the +/- range of frequencies to take max
    r = DFT'.*((f>(i*F0-5)).*(f<(i*F0+5)));
    [PKS(i),ind] = max(r);
    LOCS(i) = f(ind);
    
end

harmsum = cumsum(PKS(1:harmonics));
PKS = PKS(1:harmonics);
harmsum = harmsum(1:harmonics);

%plot
%findpeaks(DFT,f,'MinPeakHeight',11,'MinPeakDistance',80)

end
