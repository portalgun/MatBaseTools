classdef Set < handle
methods(Static)
    function [value,bA] = unique(A)
        value = A(sum(bsxfun(@eq, A(:), A(:).'))==1);
    end
    function bInd=isUnique(A,dim)
    %function bInd=isunique(A,dim)
        if exist('dim','var') && ~isempty(dim)
            dim=1;
        end
        %dim=2;
        %A=[5 8 3 4 4;...
        %    1 1 3 0 0 ];
        %Ao=A;

        dims=1:ndims(A);
        ndim=dims(dims~=dim);
        if dim~=1
            perm=[dim,ndim];
            A=permute(A,perm);
            [~,undo]=sort(perm);
        end

        sz=size(A);;
        A=num2cell(A,1);
        bInd=cellfun(@(x) Set.unique_(x),A,'UniformOutput',false);
        bInd=reshape([bInd{:}],sz);
        if dim~=1
            bInd=permute(bInd,undo);
        end
    end
    function out=isUniform(in,dim,all)
        %in={1 2 4; 1 2 3; 1 2 3};
        if exist('all','var') && ~isempty(all) && ( (isnumeric(all) && all==1) || (ischar(all) && strcmp(all,'all')) )
            bAll=1;
        else
            bAll=0;
        end
        if ~exist('dim','var') || isempty(dim)
            if islogical(in) || isnumeric(in) || ischar(in)
                out=Set.compare_num_all_(in);
            elseif iscell(in)
                out=Set.compare_cell_all_(in);
            end
        else
            if islogical(in) || isnumeric(in) || all(ischar(in))
                out=Set.compare_num_(in,dim);
            elseif iscell(in)
                out=Set.compare_cell_(in,dim);
            end
            if bAll
                out=all(out(:));
            end
        end
    end
    function out=distribute(varargin)
    %A=[1,5,6,9,12];
    %B= [1,2,3,4,5,6];
    %C= [3,18,27,69,72];
    %D= [3,18,27,69,72];
    % Set.distribute(A,B,C,D)
    %
    %A=[1,5,6,9,12];
    %B= [0,0,0,0,0,0];
    %C= [0,0,0,0,0];
    %D= [0,0,0,0,0];
    %Set.distribute(A,B,C,D)
    %
    % S={'DNW','JDB','SHK'};
    % E={'1D','2D'};
    % P=1:2;
    % K='EXP';
    % Set.distribute(S,E,P,K)

        in=varargin;
        cellind=cellfun(@iscell, varargin);
        if sum(cellind)>0
            in(cellind)=cellfun(@(x) ([1:length(x)]),varargin(cellind),'UniformOutput',0);
        end

        charind=cellfun(@ischar, varargin);
        if sum(charind)>0
            in(charind)={1};
        end

        if nargin == 2
            out=Set.Set.distribute2_(in{:});
        else
            out=Set.Set.distributeN_(in{:});
        end

        if sum(cellind)>0
            out=Set.convertback_(out,varargin,cellind,charind);
        end
    end

end
methods(Static, Access=private)
    function out=convertback_(out,orig,cellind,charind)
        ind=out;
        out=num2cell(out);
        N=find(cellind);

        % by column
        for i = N
            I=ind(:,i);
            v=transpose(orig{i});
            out(:,i)=v(I);
        end

        N=find(charind);
        for i = N
            I=ind(:,i);
            v=orig(i);
            out(:,i)=v;
        end
    end
    function out=Set.distributeN_(varargin)
        p=perms([1:nargin]);
        nP=size(p,1);

        grids=cell(nargin,1);
        [grids{:}]=ndgrid(varargin{:});
        nG=length(grids); %num dimentions

        N=nG*nP;

        K=Set.distribute(1:nG,1:size(nP,1));

        for k = 1:size(K,1)
            i=K(k,1);
            j=K(k,2);

            t=permute(grids{i},p(j,:));
            out{k}=t(:);
        end
        out=horzcat(out{:});
    end

    function C = Set.distribute2_(A,B)
        % function C = Set.distribute(A,B)
        % Set.distribute elements between vectors
        % Useful for expanding indices
        % example call:
        %           Set.distribute([3 2 1], [4 5 6])
        % CREATED BY DAVID WHITE

        %INIT
        if size(A,2)>1 && size(A,1)==1
            A=A';
        end

        if size(B,2)>1 && size(B,1)==1
            B=B';
        end

        %DISTRIBUTE
        C=repelem(A,size(B,1),1);
        D=repmat(B,size(A,1),1);
        %C=repelem(A,numel(B));
        %D=repmat(B,numel(A),1);
        if ~isequal(size(C,1),size(D,1))
            C=C';
        end

        C=[C D];
    end
    function out=compare_num_all(in)
        out=all(logical(~diff(in(:))));
    end
    function out=compare_cell_all(in)
        A=in{1};
        out=all(cellfun(@(x) isequal(x,A),in));
    end
    function out=compare_num(in,dim);
        out=all(logical(~diff(in,[],dim)),dim);
    end
    function out=compare_cell(in,dim)
        A=dimSliceSelect(in,dim,1);
        sz=size(in);
        if sz(dim) ~= 1
            sz(dim)=sz(dim)-1;
        end
        out=zeros(sz);
        col=zeros(size(sz));
        col(dim)=1;
        col=strrep(Num.toStr(double(col)),'0',':');

        for i= 2:size(in,dim)
            tmp=cellfun(@(x,y) isequal(x,y),A,dimSliceSelect(in,dim,i));
            str=['out( ' strrep(col,'1',num2str(i-1)) ' ) = tmp;'];
            try
                eval(str);
            catch ME
                disp(['ERROR IN EVAL STRING: ' str]);
                rethrow(ME);
            end

        end
        out=all(out,dim);
    end
    function un=unique_(x)
        un=sum(x==x')==1;
    end

end
end
