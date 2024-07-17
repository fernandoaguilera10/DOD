function x = loadPic(picNum)     % Load picture
picSearchString = sprintf('a%04d*.mat', picNum);
picMFile = dir(picSearchString);
if (~isempty(picMFile))
%     eval( strcat('x = ',picMFile.name(1:length(picMFile.name)-2),';') );
    load(picMFile.name,'x');
else 
    picSearchString = sprintf('p%04d*.mat', picNum);
    picMFile = dir(picSearchString);
    if (~isempty(picMFile))
%          eval( strcat('x = ',picMFile.name(1:length(picMFile.name)-2),';') );
         load(picMFile.name,'x');
    else
        error = sprintf('Picture file p%04d*.mat not found.', picNum);
        x = [];
        return;
    end
end