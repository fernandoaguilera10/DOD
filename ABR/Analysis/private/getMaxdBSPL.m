function [calibMaxdBSPL, isClick] = getMaxdBSPL(calibpicnumstr,freq)
 %Written by AS to use desired calib file
    CalibFile  = sprintf('p%04d_calib', calibpicnumstr);
    searchstr = [CalibFile,'*'];
    CalibFile = {dir(fullfile(cd,searchstr)).name};
    CalibFile = CalibFile{1};
    
    command_line = sprintf('%s%s%c','[xcal]=',CalibFile(1:end-2),';');
    eval(command_line);
    
    disp('Using RIGHT-speaker calibration for now. Adjust for new NEL!');
    
    %AS - being more precise with finding right calib file
    if strcmp(xcal.ear_ord{1},'Right ')
        CalibData = xcal.CalibData(:,1:2);
    else
        CalibData = xcal.CalibData2(:,1:2);
    end

    CalibData(:,2)=trifilt(CalibData(:,2)',5)';

    %if is nan, then assume click calibration
    if freq==0 || isnan(freq)
        %median of inv calib. Method decided on as of 06/19/2023
        calibMaxdBSPL=median(CalibData(:,2));
        isClick = 1;
    else
        calibMaxdBSPL=CalibInterp(freq/1e3, CalibData);
        isClick = 0;
    end

end