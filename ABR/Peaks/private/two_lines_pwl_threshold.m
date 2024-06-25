% Fits two lines (first horizontal) to x minimizing least-square error.
% Returns the intersection of two lines as thresh

function [w1,meanbase]=two_lines_pwl_threshold(x,y)
[x,sorted_ind]=sort(x);
y=y(sorted_ind);
allerrors=NaN(length(x),1);

for i=2:length(x)-1
    allerrors(i)=norm(y(1:i-1)-mean(y(1:i-1)))+norm(polyval(polyfit(x(i:end),y(i:end),1),x(i:end))-y(i:end));
end

[~,ind]=min(allerrors);
meanbase=mean(y(1:ind-1));

w1=fliplr([zeros(1,ind-1), 1-0.9*((y(ind:length(x))-meanbase)./(max(y(ind:length(x)))-meanbase))]);
