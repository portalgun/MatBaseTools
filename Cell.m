classdef Cell < handle
methods(Static)
    function [bInd,bIndAll]=cmp(cell1,cell2)
        bIndAll=0;
        bInd=0;
        if ndims(cell1)~=ndims(cell2)
            warning('Cell.cmp: Cells are have different dimensions.')
            return
        end
        if any(size(cell1)~=size(cell2))
            warning('Cell.cmp: Cells are not of the same size.')
            return
        end
        bInd=cellfun(@isequal,cell1,cell2);
    end
    function bIndAll=similar(A,bTrans)
        bIndAll=zeros(size(A));
        for i = 1:numel(A)
            bInd=cellfun(@(x) isequal(A{i},x),A);
            bIndAll(bInd & ~logical(bIndAll))=i;
        end
        ind=find(bIndAll==0);
        for i = transpose(ind)
            bIndAll(i)=i;
        end
    end
    function [A] = hashes(C)
        %Convert cell of strings into array of hash.
        %hashes will come out the same for the same strings
        %Great for comparing strings
        Opt.Method='MD5';
        Opt.Format='double';
        Opt.Input='ascii';
        A = cell2mat(cellfun(@(x) str2double(strrep(num2str(DataHash(x, Opt)),' ','')),C,'UniformOutput',false));
    end
    function [C,flds] = sortSize(C,flds)
        SZ={};
        D=[];
        for i = 1:size(C,1)
            sz=size(C{i});
            d=ndims(C{i});
            if ~ismember(d,D)
                D(end+1,1)=d;
                ind=length(D);
            else
                ind=find(ismember(D,d));
            end
            SZ{end+1,ind}=C{i};
        end

        D={};
        for j = 1:size(SZ,2)
            bInit=1;
            for i = 1:size(SZ,1)
                e=SZ{i,j};
                if isempty(e)
                    continue
                end
                sz=size(e);
                if bInit==1;
                    bInit=0;
                    SZD=sz;
                    ind=1; %size index, not C index
                elseif ~ismember(sz,SZD,'rows')
                    SZD(end+1,:)=sz;
                    ind=size(SZD,1);
                else
                    ind=find(ismember(SZD,sz,'rows'));
                end
                D{i,ind,j}=e;
            end
        end

        Call=cell(size(D,2).*size(D,3));
        INDS=cell(size(D,2).*size(D,3));
        l=0;
        for i = 1:size(D,2)
            for j = 1:size(D,3);
                l=l+1;
                e=D(:,i,j);
                if isempty(e)
                    continue
                end

                bInd=cellfun(@isempty,e);
                e(bInd)=[];

                if isempty(e)
                    continue
                end

                INDS{l}=find(~bInd);

                sz=size(e{1});
                if isequal(sz(2),1) && numel(sz)==2
                    E=zeros(sz(1),size(e,1));
                else
                    E=zeros([sz size(e,1)]);
                end

                dims=ndims(E);
                ddim=ndims(E);
                for k = 1:size(e)
                    col=num2Colons(dims,dims,k);
                    ee=e{k};

                    str=['E(' col ')=ee;'];
                    eval(str);
                end
                Call{l}=E;
            end
            bInd=cellfun(@isempty,Call);
            Call(bInd)=[];
            INDS(bInd)=[];
            C=Call';
            INDS=INDS';
        end
        Names=cell(size(INDS));
        for k = 1:size(INDS,1)
            ind=INDS{k};
            E=cell(size(ind,1),1);
            for j=1:size(ind,1)
                i=ind(j);
                E{j}=flds{i};
            end
            Names{k}=E;
        end
        flds=Names;

        ind=cellfun(@ndims,C)>3;
        C(ind)=[];
        flds(ind)=[];

        ind=cellfun(@ndims,C)==2;

        D=C{ind};
        Dflds=flds{ind};
        C(ind)=[];
        flds(ind)=[];

        nUnique=sum(diff(sort(D))~=0)+1;

        %Logical elements to their own array
        bInd=nUnique==2;
        B=D(:,bInd);
        Bflds=Dflds(transpose(bInd));

        %Remove logical and bad arrays
        bInd=nUnique<=2;
        D(:,bInd)=[];
        Dflds(bInd)=[];


        sz=cellfun(@(x)size(x,2),C);
        [~,ind]=sort(sz);
        C=C(ind);
        flds=flds(ind);

        ind=cellfun(@(x)size(x,2),C)>10;
        C(ind)=[];
        flds(ind)=[];

        C=[D;B;C];
        flds=[{Dflds};{Bflds};flds];
    end
    function str=print(A,justification,sep,nfloat)
        if ~exist('A','var') || isempty(A)
            A={'abcd', 'efg', 'hij'; 1, 2 'jklm'};
            justification='left';
        end
        if ~exist('sep','var')
            sep= '  ';
        end
        if ~exist('nfloat','var') || isempty(nfloat)
            nfloat=4;
        end

        A=Cell.convert(A);
        colSz=Cell.get_col_sz(A);
        A=Cell.justify(A,colSz,justification,nfloat);


        A=join(A,sep,2);
        str=join(A,newline,1);
        str=str{1};
        if nargout < 1
            disp(str);
        end
    end
end
methods(Static, Access=private)
    function A=convert(A)
        ind=find(cellfun(@(x) ~ischar(x) && ~isnumeric(x) ,A));
        if isempty(ind)
            return
        end
        for ii = length(ind)
            i=ind(ii);
            A{i}=[];
        end
    end
    function colSz=get_col_sz(A)
        colSz=max(cellfun(@numel,A),[],1);
    end
    function A=justify(A,colSz,justification,nfloat)
        INDS=Set.distribute(1:size(A,1),1:size(A,2));
        for i = 1:length(INDS)
            r=INDS(i,1);
            c=INDS(i,2);
            sz=colSz(c);
            val=A{r,c};

            fl='';
            if Num.isInt(val)
                e='i';
            elseif Num.is(val)
                e='f';
                if mod(val,1) > 0
                    fl=['.' num2str(nfloat)];
                end
            elseif ischar(val)
                e='s';
            end
            if strcmp(justification,'right')
                j= ' ';
            elseif strcmp(justification,'left')
                j='-';
            end
            f=['%' j num2str(sz) fl  e];
            A{r,c}=sprintf(f,val);
        end

    end




end
end
