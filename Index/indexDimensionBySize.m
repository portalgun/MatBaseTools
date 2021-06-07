function thing = indexDimensionBySize(ind,sz,thing,bOneInd)
    if ~exist('bOneInd','var') || isempty(bOneInd)
        bOneInd=0;
    end
    dim=size(thing)==sz;
    if bOneInd && sum(dim)>1 && ndims(thing) <= 2 && dim(1)==1
        dim=logical(zeros(size(sz)));
        dim(1)=1;
    else
        i=find(dim,1,'last');
        dim=logical(zeros(size(dim)));
        dim(i)=1;
    end
    col=strrep(Num.toStr(double(dim)),'0',':');
    col=strrep(col,'1','ind');
    if iscell(thing)
        STR=['thing{' col '};'];
    else
        STR=['thing(' col ');'];
    end
    thing=eval(STR);
end
