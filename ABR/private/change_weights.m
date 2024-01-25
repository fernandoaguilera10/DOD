function change_weights

global data spl w num include_spl include_zscore include_w

%HG ADDED 2/3/20 - HERE
% round_spl = round(spl);
% find_spl = find(round_spl <= 60);
% include_spl = spl(find_spl);
% include_zscore = data.z.score(find_spl);
% include_w = w(find_spl);
new_num = length(include_spl);
    

%x=min(spl)-10; 
x=min(include_spl)-10; 
%distance=NaN(1,num);
distance = NaN(1,length(include_spl));
marker=1;
% while x >= min(spl)-10 && x <= max(spl)+10 && marker ~=2
while x >= min(include_spl)-10 && x <= max(include_spl)+10 && marker ~=2
    [x,y,marker] = ginput(1);
    
	%for i=1:num
    for i=1:new_num
		%distance(1,i)=abs(x-spl(1,i))/(max(spl)+10-min(spl)-10)+abs(y-data.z.score(1,i))/max(data.z.score)/1.1;
        distance(1,i)=abs(x-include_spl(1,i))/(max(include_spl)+10-min(include_spl)-10)+abs(y-include_zscore(1,i))/max(include_zscore)/1.1;
	end
	[~,index]=min(distance);
	%if marker == 1 && x >= min(spl)-10 && x <= max(spl)+10
    if marker == 1 && x >= min(include_spl)-10 && x <= max(include_spl)+10 %ADD POINT BACK IN -- MARKER=1, SINGLE CLICK
		%w(1,index)=1;
        include_w(1,index)=1;
	%elseif marker ==3 && x >= min(spl)-10 && x <= max(spl)+10
    elseif marker ==3 && x >= min(include_spl)-10 && x <= max(include_spl)+10 %REMOVE POINT -- MARKER=3, DOUBLE CLICK
		%w(1,index)=0;
        include_w(1,index)=0;
	end

	%X=ones(num,2);
    X=ones(new_num,2);
	%X(:,2)=spl';
    X(:,2)=include_spl';
	%b=lscov3(X,data.z.score',w');
    b=lscov3(X,include_zscore',include_w');
	data.z.slope=b(2,1);
    data.z.intercept=b(1,1);
	data.threshold=(3-b(1,1))/b(2,1);

    stop=1;
    vertLineMarker = 0;
	plot_data2(stop,vertLineMarker);
	
end