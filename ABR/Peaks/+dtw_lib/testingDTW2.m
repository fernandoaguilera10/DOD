clear;
close all;
clc;

sig1=[zeros(100,1); linspace(0,1,100)'; linspace(1,0,200)';zeros(150,1);linspace(0,1,100)'; linspace(1,0,250)';zeros(150,1);];
sig1=sig1+0.01*randn(size(sig1));

sig2=[zeros(200,1);linspace(0,1,200)'; linspace(1,0,100)';zeros(150,1);linspace(0,1,200)'; linspace(1,0,100)';zeros(100,1);];
sig2=sig2+0.01*randn(size(sig2));


subplot(311);
plot(sig1);
hold on;
plot(sig2,'r');
title('original signals');
legend('sig1 untouched','sig2 untouched');


D=dtw(sig1,sig2,300);
ind2=align_time(D);

subplot(312);
plot(sig1);
hold on;
plot(sig2(ind2),'r');
title('itme-warped signals');
legend('sig1 untouched','sig2 warped');


subplot(313);
ind_2ndord= round(smooth(ind2,0.1,'rloess'));
ind_2ndord(ind_2ndord<=0)=1;
ind_2ndord(ind_2ndord>size(D,1))=size(D,1);
plot(sig1);
hold on;
plot(sig2(ind_2ndord),'r');
title('time-warped signals');
legend('sig1 untouched','sig2 warped and 2nd order poly smoothed');
