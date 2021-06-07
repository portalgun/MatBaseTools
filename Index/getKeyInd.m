function [key] = getKeyInd(S,flds)
    if ~exist('flds','var')
        flds=[];
    end
    if iscellstruct(S)
        key=getKeyIndCellStruct(S,flds);
    elseif isstruct(S)
        key=getKeyIndStruct(S,flds);
    end

end
function key=getKeyIndCellStruct(S,flds)
    key=zeros(numel(S),1);
    for i = 1:numel(S)
        if isempty(S{i})
            continue
        end
        if numel(fieldnames(S{i}))==0
            continue
        end
        k=getKeyIndStruct(S{i},flds);
        if isempty(k)
            continue
        end
        key(i)=k;
    end
    X=unique(key);
    counts=hist(key,X);
    if sum(X~=0) == 1
        key=X(X~=0);
    else
        X=X(X~=0);
        counts=counts(X~=0);
        key=X(counts==max(counts));
    end
end
function key=getKeyIndStruct(S,flds)
    if isempty(flds)
        flds=fieldnames(S);
    end
    SZ=[];
    for i = 1:numel(flds)
        fld=flds{i};
        if ~isfield(S,fld)
            continue
        end
        sz=size(S.(fld));
        sz=sz(:);
        SZ=[SZ; sz];
    end
    SZ(SZ==1)=[];
    X=unique(SZ);
    if numel(X) > 1
        [count]=hist(SZ,X);
        key=X(count==max(count));
    else
        key=X;
    end
    if numel(key) > 1
        key=max(key);
    end
end
