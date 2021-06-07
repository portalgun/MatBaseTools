function B=dimElemRm(A,dim,ind)
%select a specific slice across dimension dim at subscript x
%good for indexing when your dim is variable across dimensions
%example call:
%  A=rand(5,10,3)
%  B=dimSliceSelect(A,3,2)
%  A=(:,:,2)==B

S.subs = repmat({':'},1,ndims(A));
All=[1:size(A,dim)];
S.subs{dim} = ind;
S.type = '()';
B = subsasgn(A,S,[]);
