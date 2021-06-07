function out=appendBYKeyDim(S,bStack,key)
    if ~exist('bStack','var') || isempty(Bstack)
        bStack=0;
    end
    if nargin < 3
        key=getKeyDim(S);
    end
end
