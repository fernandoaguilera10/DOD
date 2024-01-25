% Copyright (C) 2013 Quan Wang <wangq10@rpi.edu>,
% Signal Analysis and Machine Perception Laboratory,
% Department of Electrical, Computer, and Systems Engineering,
% Rensselaer Polytechnic Institute, Troy, NY 12180, USA

% this is a demo showing the use of our dynamic time warping package
% we provide both Matlab version and C/MEX version
% the C/MEX version is much faster and highly recommended

clear;
clc;
close all;

mex dtw_SP.c;

a=rand(500,1);
b=[rand(20,1); a(1:480)];
w=50;

D1=dtw(a,b,w);
d1=min(min(D1(D1~=0)));

D2=dtw(a,b,w);
d2=D2(end,end);
