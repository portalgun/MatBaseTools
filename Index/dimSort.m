function B=dimSort(A,dim,ind)
%  Sort A by indeces 'ind' across dimension 'dim'
%  A=randi(10,10,1)
%  [C,ind]=sort(A,1)
%  B=A';
%  D=dimSort(B,2,ind)
%  find(C==D')


if size(ind,1)<size(ind,2)
  ind=ind';
end

S.type = '()';
S.subs = repmat({':'},1,ndims(A));
S.subs{dim} = ind;
try
    B = subsref(A,S);
catch
    rethrow(ME);
end
