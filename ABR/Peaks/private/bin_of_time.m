% bin=bin_of_time(time_ms)
% input: time in ms
function bin=bin_of_time(time_ms)
global dt
bin=1+round(time_ms/dt);