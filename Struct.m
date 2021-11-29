classdef Struct < handle
methods(Static)
    function vals=arrSelect(S,fld, bInd)
        if nargin < 3
            vals={S.(fld)};
        else
            vals={S(bInd).(fld)};
        end

        if ~isequal(size(vals) ,size(S))
            vals=transpose(vals);
        end
        if cellfun(@(x) isnumeric(x) || islogical(x) && numel(x)==1,vals)
            vals=cell2mat(vals);
        end
        if nargin < 3
            return
        end
    end
    function Snew=combinePref(Sprefer,S,bEmpty,bRecurse)
        % bEmpty=0  means empty field treated as if it doesn't exist
        if ~exist('bEmpty')
            bEmpty=1;
        end
        if nargin < 4
            bRecurse=false;
        end
        fldsP=fieldnames(Sprefer);
        fldsS=fieldnames(S);

        Snew=Sprefer;
        for i = 1:length(fldsS)
            fld=fldsS{i};
            if ~ismember(fld,fldsP) || (~bEmpty && isempty(Snew.(fld)) && ~isempty(S.(fld)))
                Snew.(fld)=S.(fld);
            elseif bRecurse && isstruct(Snew.(fld)) && isstruct(S.(fld))
                Snew.(fld)=Struct.combinePref(Snew(fld),S.(fld),bEmpty,true);
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
    function S=rmFlds(S,fldsrm)
    %function Snew=structRmFlds(S,fldsrm)
        flds=fieldnames(S);
        if isstruct(fldsrm)
            fldsrm=fieldnames(fldsrm);
        end
        for i = 1:length(flds)
            fld=flds{i};
            if ismember(fld,fldsrm)
                S=rmfield(S,fld);
            end
        end
    end
    function S=fromPairs(keys,vals)
        if Num.is(vals)
            vals=num2cell(vals);
        end
        vals=Vec.col(vals);
        keys=Vec.col(keys);
        T=transpose([keys vals]);
        S=struct(T{:});

        %for i = 1:length(keys)

        %end
    end
    function [flds,vals]=toCell(in)
        %in=struct();
        %in.B=struct('a',1,'b',2);
        %in.C=struct('c',struct('e',3),'d',4);
        obj=struct2cell_c(in);
        flds=obj.flds;
        vals=obj.vals;
    end

    function S=merge(varargin)
    % combine same dimension struct accross new dimsension
        [dims,FLDS]=Struct.getCatDims(varargin{:});

        if isempty(dims) && isempty(FLDS) %DONT SHARE ANY FIELDS
            S=Struct.naive_merge_fun(varargin);
            return
        end
        S=Struct.mergeFldsAtDims(FLDS,dims,varargin{:});
    end
    function Snew = mergeFldsAtDims(flds,dims,varargin)
        Snew=struct;
        for i = 1:length(flds)
            fld=flds{i};
            dim=dims(i);
            if dim == 0
                SNew.(fld)=[];
                continue
            end
            bChar=cellfun(@(x) ischar(x.(fld)),varargin);
            s=cellfun(@(x) x.(fld) ,varargin,'UniformOutput',false);
            if all(bChar)
                Snew.(fld)=s;
            else
                Snew.(fld)=cat(dim,s{:});
            end
        end
    end

    function [dims,FLDS]=getCatDims(varargin)
        % FIRST SUITABLE size of 1 for each fld

        flds=cellfun(@fieldnames,varargin,'UniformOutput',false);
        FLDS=flds{1};
        for i = 2:length(flds)
            FLDS=intersect(FLDS,flds{i});
        end

        dims=zeros(length(FLDS),1);
        for i = 1:length(FLDS)
            fld=FLDS{i};
            sizes=cellfun(@(x) size(x.(fld)),varargin,'UniformOutput',false);
            sizes=vertcat(sizes{:});
            %sizes(sizes==max(sizes,[],2))=inf;
            if any(diff(sizes,[],1))
                continue
            end

            s1 =sizes(1,:);
            if s1(1)==1 & s1(end)==1
                dims(i)=1;
            elseif s1(end)==1
                dims(i)=numel(s1);
            else
                dims(i)=numel(s1)+1;
            end
        end
    end
end
methods(Static,Access=private)
    function Snew=naive_merge_fun(SS)
        Snew=struct();
        for i=1:length(SS)
            flds=fieldnames(SS{i});
            for f = 1:length(flds)
                fld=flds{f};
                Snew.(fld)=SS{i}.(fld);
            end
        end
    end

end
end
