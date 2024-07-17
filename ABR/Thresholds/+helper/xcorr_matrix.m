function cor = xcorr_matrix(A,B)
%Author (s): Andrew Sivaprakasam
%Last Updated: Februrary, 2024
%Description: Pairwise xcorr columns of matrix A with B. making this a fxn
%for now so it's easier to make more efficient later.

    %make sure A and B are same size
    if(~isequal(size(A),size(B)))
        error('Please make sure A and B are equal in size!')
    end 

    %preallocate
    cor = zeros(2*size(A,1)-1,size(A,2));

    %pairwise cross-correlate
    for i = 1:size(A,2)
        cor(:,i) = xcorr(A(:,i),B(:,i),'normalized');
    end    

end

