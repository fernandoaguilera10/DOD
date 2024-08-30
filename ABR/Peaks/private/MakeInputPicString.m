function PicString=MakeInputPicString(PicNums)

% Takes the input number array (eg, [5,6,7,9]) and turns it into an string (e.g. '5-7,9')
% SP (23 Aug, 2016)

PicNums=sort(PicNums);

ind_group_start=[1 find(diff(PicNums)~=1)+1];
ind_group_end=[ind_group_start(2:end)-1 length(PicNums)];

PicString ='';

for i=1:length(ind_group_start)
    if ind_group_start(i)==ind_group_end(i)
        PicString=[PicString num2str(PicNums(ind_group_end(i))) ',']; %#ok<*AGROW>
    else 
        PicString=[PicString num2str(PicNums(ind_group_start(i))) '-' num2str(PicNums(ind_group_end(i))) ','];
    end    
end

PicString=PicString(1:end-1);