classdef Struct < handle
methods(Static)
    function Snew=combinePref(Sprefer,S,bEmpty)
        if ~exist('bEmpty')
            bEmpty=0;
        end
        fldsP=fieldnames(Sprefer);
        fldsS=fieldnames(S);

        Snew=Sprefer;
        for i = 1:length(fldsS)
            fld=fldsS{i};
            if ~ismember(fld,fldsP)
                Snew.(fld)=S.(fld);
            end
        end
    end
    function n=nfld(S)
        n=numel(fieldnames(S));
    end
    function S=rename(S,name,newname)
        val=S.(name);
        flds=fieldnames(S);
        ind=find(ismember(flds,name));
        S=rmfield(S,name);
        S.(newname)=val;

        n=numel(flds);
        if n==1 || ind == n
            return
        end

        if ind == 1
            s=[];
        else
            s=1:ind-1;
        end

        e=ind+1:n;
        P=[s n e-1];
        S=orderfields(S,P);
    end
end
end
