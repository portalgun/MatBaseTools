function ind = sub2indAmbig(sz,sub)
% TODO VECTORIZE
if numel(sz) ~= size(sub,2)
    error('sub2indAmbig: row dimension must match')
end
nSubs=numel(sz);
ind=zeros(size(sub,1),1);
for j = 1:size(sub,1)
    STR = '';
    for i = 1:nSubs
        str=[ 'sub(' num2str(j) ',' num2str(i) '),'];
        STR=[STR str];
    end
    STR(end) = ')';
    STR=[ 'ind(j) = sub2ind(sz,' STR ';'];
    eval(STR);
end

%myIxs = arrayfun(@(rowIx,colIx) sub2ind(size(A),rowIx,colIx), i(:,1), i(:,2));
%A(myIxs)
