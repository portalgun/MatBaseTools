function s = ind2subAmbig(sz,ind)
nSubs=numel(sz);
STR = '[' ;
for i = 1:nSubs
    str=[ 's(' num2str(i) '),'];
    STR=[STR str];
end
STR(end)= ']';
s=zeros(1,numel(sz));
eval([ STR '=ind2sub(sz,ind);']);
