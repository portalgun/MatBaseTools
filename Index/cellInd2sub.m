function SUBS = cellInd2sub(PszRC,ind)
%ind2subs of ind vectors (of same size) that are in cells - returns cells of subs
% example call:
%
%CREATED BY DAVID WHITE
[n,m]=ind2sub(PszRC,vertcat(ind{:}));

RC=cellfun(@(x) size(x,1),ind);
cumul=cumsum(RC)';
tmp=[1; cumul+1];
Subs=[tmp(1:end-1) cumul];

SUBS=arrayfun(@(x,y) [n(x:y) m(x:y)],Subs(:,1),Subs(:,2),'UniformOutput',false);
