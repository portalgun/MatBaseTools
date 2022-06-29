classdef Cell < handle

methods(Static)
    function txt=toStr(C,nspace,sepCol,sepRow,alignChar)
    %function txt=toStr(C,nspace,sepCol,sepRow,alignChar)
        %C={'bin','1','2'; 'val','1',''};
        %
        if nargin < 2 || isempty(nspace)
            nspace=0;
        end
        if nargin < 3
            sepCol=' ';%char(44);
        end
        if nargin < 4
            sepRow=newline;
        end
        if nargin < 5
            alignChar='left';
        end

        txt=cell(size(C));
        for i = 1:size(C,2)
            flds=C(:,i);
            if iscell(flds) && numel(flds)==1 && iscell(flds{1})
                flds=flds{1};
            end
            ninds=cellfun(@isnumeric,flds);
            linds=cellfun(@islogical,flds);
            oinds=cellfun(@isobject,flds) | cellfun(@iscell,flds);
            if all(ninds) && ~all(cellfun(@isempty,flds))
                flds=cellfun(@Num.toStr,flds,'UniformOutput',false); %- SLOW
                flds=split(flds,newline);
            else
                J=find(ninds);
                for jj = 1:length(J)
                    j=J(jj);
                    if numel(flds{j} > 20)
                        flds{j}=Range.str(flds{j});
                    else
                        flds{j}=Num.toStr(flds{j});
                    end
                end
                J=find(oinds);
                for jj = 1:length(J)
                    j=J(jj);
                    sz=strrep(Num.toStr(size(flds{j})),',',char(215));
                    flds{j}=[sz ' ' class(flds{j})];
                end

                J=find(linds);
                for jj = 1:length(J)
                    j=J(jj);
                    if flds{i}
                        str='true';
                    else
                        str=false;
                    end
                    sz=strrep(Num.toStr(size(flds{j})),',',char(215));
                    flds{j}=strrep(Num.toStr(flds{j}),'1','true');
                    flds{j}=strrep(flds{j},'0','false');
                end
            end
            if i==size(C,2)
                n=0;
            else
                n=nspace;
            end
            if i==size(C,2)
                sepp='';
            else
                sepp=sepCol;
            end
            txt(:,i)=Cell.space_fun(flds,n,sepp,alignChar); %- SLOW
        end
        l=size(C,1);
        str=cell(l,1);
        for i = 1:l
            str{i}=strjoin(txt(i,:),''); %- Slow
        end
        txt=strjoin(str,sepRow);


    end
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
    function [dupNdxs,dupNames]=findDuplicates(lines)
        [uniqueList,~,uniqueNdx] = unique(lines);
        N = histc(uniqueNdx,1:numel(uniqueList));
        dupNames = uniqueList(N>1);
        dupNdxs = arrayfun(@(x) find(uniqueNdx==x), find(N>1), 'UniformOutput',false);
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

    function flds=space_fun(flds,n,sep,alignChar)
        col=max(cellfun(@(x) size(x,2), flds))+n;
        if strcmp(alignChar,'left')
            for i = 1:length(flds)
                space=repmat(' ',1, col-size(flds{i}, 2));
                flds{i}=[flds{i} sep space];
            end
        elseif strcmp(alignChar,'right')
            for i = 1:length(flds)
                space=repmat(' ',1, col-size(flds{i}, 2));
                flds{i}=[space flds{i} sep];
            end

        else
            inds=cellfun(@(x) find(x==alignChar,1,'first'),flds);
            m=max(inds)
            for i = 1:length(flds)
                nrep=m-inds(i);
                nrep2=col-size(flds{i},2)-nrep;
                space1=repmat(' ',1, nrep);
                space2=repmat(' ',1, nrep2);
                flds{i}=[ space1 flds{i} sep space2 ];
            end
        end
    end



end
end
