% function D=dtw(a,b,w)
% This function aligns two signals using Dynamic Time Warping
% Input: 
%   a=first signal
%   b=second signal
%   w=max window for time alignment (see Wikipedia)
%  Output: 
%   D=distance matrix 
%  Use D to trace back the optimal path.
%  Written by: SP

function D=dtw(invec1,invec2,w)

if nargin~=3
    error('Number of input parameters should be 3');
end
if size(invec1,1)~=length(invec1)
    invec1=invec1';
end

if size(invec2,1)~=length(invec2)
    invec2=invec2';
end

% fprintf('%d is the window length',w);
D=dtw_lib.dtw_SP(invec1,invec2,w);

D(D==1e6)=NaN;