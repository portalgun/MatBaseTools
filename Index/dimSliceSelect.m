function B=dimSliceSelect(A,dim,x)
%select a specific slice across (not with) dimension dim at subscript x
%good for indexing when your dim is variable across dimensions
% NOTE dim is what dimension you want to 'remove'
%example call:
%  A=rand(5,10,3)
%  B=dimSliceSelect(A,3,2)
%  A(:,:,2)==B
if dim==ndims(A)+1
    dim=1;
end

S.subs = repmat({':'},1,ndims(A));
All=[1:size(A,dim)];
if numel(x)==1
    All(All==x)=[]; %All but x
else
    All(ismember(All,x))=[]; %All but x
end
S.subs{dim} = All;
S.type = '()';
B = subsasgn(A,S,[]);
