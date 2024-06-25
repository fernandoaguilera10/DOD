function [mn] = boots(data,samps,iters)
%%Author (s): Andrew Sivaprakasam
%Last Updated: Februrary, 2024
%Description: General purpose bootstrap (random sampling w/replacement) 
% function (returns N means)

    inds = randi(size(data,2),samps,iters);
    select = data(:,inds);
    select = reshape(select,size(data,1),samps,iters);

    mn = squeeze(mean(select,2));

end

