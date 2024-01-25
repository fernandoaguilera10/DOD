% Monotonicity, warping window boundaries are integrated in this code
% Created by SP: 19 Aug, 2016

function ind2=align_time(D)

ind2=zeros(size(D,2),1);

base_ind=size(D,1)-100;
allowed_rows=base_ind+1:size(D,1);

for i=length(ind2):-1:2
   [~,min_ind]=min(D(allowed_rows,i));
   ind2(i)=min_ind+base_ind;
   allowed_rows=base_ind+min_ind-2:base_ind+min_ind;
   allowed_rows(allowed_rows<=0)=[];
   allowed_rows(allowed_rows>size(D,1))=[];
   base_ind=allowed_rows(1)-1;
end

ind2=ind2(2:end)-1;
