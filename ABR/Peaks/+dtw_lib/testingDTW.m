clear;
close all;
clc;

nzPart=[linspace(0,1,100)'; linspace(1,0,200)'];
sig1=[zeros(250,1);nzPart ; zeros(250,1)];
sig1=sig1+0.00*randn(size(sig1));

sig2=[zeros(200,1); nzPart; zeros(300,1)];
sig2=sig2+0.00*randn(size(sig2));

subplot(211);
plot(sig1);
hold on;
plot(sig2,'r');

legend('sig1','sig2');


D=dtw(sig1,sig2,75);
ind1=align_time(D);

subplot(212);
plot(sig1(ind1));
hold on;
plot(sig2,'r');



% figure; 
% plot(ind2);