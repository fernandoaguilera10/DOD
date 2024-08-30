%[calibi]=read_calib_interpolated(calfile,f)
%	Usage: type read_calib('p0001_calib') for p0001_calib.m
%  Program outputs calibration values interpolated to frequency vector f, in kHz
%  Run from DAinloop_noisebands.m

function [calibi]=read_calib_interpolated(calfile,f)


%load calibration file
run(calfile);
eval('x=ans');
calib=x.CalibData(:,1:3);

calibi=zeros(1,length(f));
for i=1:length(f)
    if f(i)<min(calib(:,1))
        calibi(i)=calib(1,2);
    elseif f(i)>min(calib(:,1)) && f(i)<max(calib(:,1))
        j=find(calib(:,1)<=f(i), 1, 'last' );   %in kHz
        calibi(i)=(f(i)-calib(j,1))/(calib(j+1,1)-calib(j,1)) ...
            *(calib(j+1,2)-calib(j,2)) + calib(j,2);	%linear interpolation of frequency
    elseif f(i)>max(calib(:,1))							% to get the appropriate calib.level
        calibi(i)=calib(end,2);
    end
end
fprintf(1,'Note: calibration correction only valid for range %.2f-%.2f kHz\n',calib(1,1),calib(end,1));

return