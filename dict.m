classdef dict < handle & matlab.mixin.CustomDisplay
properties(Hidden)
    %keys
    vals
    zeroval
    map
end
properties(Access=private)
    order={}
    bOrdered=false
end
methods
    function obj =dict(varargin)
        in=varargin;
        n=length(varargin);
        bStruct=false;
        if mod(n,2)~=0
            if ~isempty(in) && (islogical(in{1}) || isnumeric(in{1})) && numel(in{1})==1 && in{1}==1
                obj.bOrdered=true;
                in(1)=[];
                n=n-1;
            elseif numel(varargin)==1 && isstruct(varargin{1});
                bStruct=true;
            else
                error('must have even number of inputs');
            end
        end

        if bStruct
            keys=fieldnames(varargin{1});
            vals=struct2cell(varargin{1});
        elseif numel(in)==2 && iscell(in{1}) && iscell(in{2})
            keys=in{1};
            vals=in{2};
            if isempty(keys)
                keys=cellfun(@num2str,num2cell(1:length(vals)'),'UniformOutput',false);
            end
        else
            keys=in(1:2:n);
            vals=in(2:2:n);
        end

        bad=~cellfun(@ischar, keys);
        if any(bad)
            error('invalid key value');
        end
        % XXX TODO HANDLE DUPCLICATES
        if ~isempty(keys)
            obj.map=containers.Map(keys,vals,'UniformValues',false);
        else
            obj.map=containers.Map('UniformValues',false);
        end
        if ~isempty(keys)
        %if obj.bOrdered && ~isempty(keys)
            obj.order=Vec.col(keys);
        end
    end
    function obj=subsasgn(obj,S,val)
        if numel(S) > 1;

            if numel(S) > 2
                subs=[S(1:end-2).subs];
                parent=obj.recurse(subs{:});
            else
                parent=obj;
            end
            child=subsref(parent,S(end-1));
            % if a dict, can assign to it directly
            % if a cell have to assign to parent b.c. handle class
            if isa(child,'dict')
                subsasgn(child,S(end),val);
            elseif iscell(child)
                child{S(end).subs{:}}=val;
                subsasgn(parent,S(end-1),child);
            end
            return
        end
        fld=S.subs{1};
        k=obj.keys;
        if isnumeric(fld)
            if isnumeric(fld) &&  fld-1==numel(obj)
                fld=num2str(fld);
            elseif isnumeric(fld) && fld==0
                obj.zeroval=val;
                return
            else
                fld=k{fld};
            end
        end
        if isnumeric(val) && isempty(val) && strcmp(S.type,'()')
            remove(obj.map,fld);
            %if obj.bOrdered
                obj.order(ismember(obj.order,fld))=[];
            %end
            return
        end
        obj.map(fld)=val;
        try
        %if obj.bOrdered && ~ismember(fld,k)
        if ~ismember(fld,k)
            obj.order{end+1,1}=fld;
        end
        catch ME
            fld
            k
            rethrow(ME)
        end
        %catch
        %    remove(obj.map,fld);
        %    obj.map(fld)=val;
        %    error('need to resort') % TODO
        %end
    end
    function n=numArgumentsFromSubscript(obj,s,indexingContext)
        n=1;
    end
    function keys=keys(obj)
        keys=obj.order;
        %if obj.bOrdered
        %    %[~,ind]=sort(obj.order);
        %    %[~,ind]=sort(ind);
        %    %keys=keys(ind);
        %    keys=obj.order;
        %else
        %    keys=obj.map.keys'; % XXX SLOW
        %end
    end
    function out=iskey(obj,name)
        keys=obj.map.keys';
        out=ismember(name,keys);
    end
    function vals=get.vals(obj)
        vals=values(obj.map)';
        if obj.bOrdered
            [~,ind]=sort(obj.order);
            [~,ind]=sort(ind);
            vals=vals(ind);
        end
    end
    function keys=fieldnames(obj)
        keys=obj.keys();
    end
    function out=isfield(obj,fld)
        out=obj.map.isKey(fld);
    end
    function out=numel(obj)
        out=size(keys(obj.map),2);
    end
    function out=isempty(obj)
        out=size(keys(obj.map),2)==0;
    end
    function out=size(obj)
        out=fliplr(size(keys(obj.map)));
    end
    function out=isnan(obj)
        out=all(cellfun(@(x) numel(x) == 1 && isnumeric(x) && isnan(x),obj.vals));
    end
    function out=plus(obj)

    end
    function out=recurse(obj,varargin)
        inds=varargin;
        for i = 1:length(inds)
            s(i)=struct('type','{}','subs',[]);
            s(i).subs=inds(i);
        end
        out=obj.subsref(s);
    end
    function out=keyInd(obj,key)
        out=ismember(obj.keys,key);
    end
    function out=valInd(obj,val)
        out=cellfun(@(x) isequal(x,val),obj.vals);
    end
%% MODIFY
    function rename(obj,name,newName)
        val=obj.map(name);
        obj.map=remove(obj.map,name);
        obj.map(newName)=val;
        obj.order{ismember(obj.order,name)}=newName;
    end
    function out=rmfield(obj,varargin)

        bCopy=false;
        if nargout > 0
            out=copy(obj);
            bCopy=true;
        end
        for i = 1:length(varargin)
            fld=varargin{i};
            if bCopy
                out.map=remove(out.map,fld);
                %if obj.bOrdered
                    out.order(ismember(obj.order,fld))=[];
                %end
            else
                obj.map=remove(obj.map,fld);
                %if obj.bOrdered
                    obj.order(ismember(obj.order,fld))=[];
                %end
            end
        end
    end
    function out=merge(obj,dict2)
    end
    function new=copy(obj)
        new=Obj.copy(obj);
        return
        new=dict(obj.bOrdered);
        s=Obj.struct(obj,false);
        flds=fieldnames(s);
        for i = 1:length(flds)
            if isa(s.(flds{i}),'dict')
                new.(flds{i})=copy(s.(flds));
            elseif strcmp(flds{i},'map')
                new.(flds{i})=Obj.copy(s.map);
            else
                new.(flds{i})=s.(flds{i});
            end
        end
    end
    function [match,remain]=split(obj,re)
        s=struct('type','()','subs',[]);
        matchkeys=obj.RE(re);
        kees=obj.keys;
        notkeys=kees(~ismember(kees,matchkeys));


        match=copy(obj);
        s.subs=matchkeys;
        match=match.subsref(s);

        remain=copy(obj);
        s.subs=notkeys;
        remain=remain.subsref(s);

    end
    function kees=RE(obj,re)
        new=dict();
        kees=obj.keys;
        kees=kees(Str.RE.ismatch(kees,re));
    end
    function out=mergePref(obj,dict2,bEmpty,bRecurse)
        if nargin < 3
            bEmpty=1;
        end
        if nargin < 4
            bRecurse=false;
        end
        keys1=obj.keys;
        keys2=dict2.keys;

        Newd=obj.copy;
        s=struct('type','{}','subs',[]);
        for i = 1:length(keys2)
            fld=keys2{i};
            s.subs={fld};
            val=subsref(dict2,s);
            bis=false;
            if ismember(fld,keys1)
                newfld=subsref(obj,s);
                bis=true;
            end
            if ~bis || (~bEmpty && isempty(newfld) && ~isempty(val))
                subsasgn(Newd,s,val);
            elseif bis && bRecurse && isa(val,'dict')
                n=subsref(Newd,s);
                dic=n.mergePref(val,bEmpty,true);
                subsasgn(Newd,s,dic);
            end
        end
        if nargout > 0
            out=Newd;
        else
            error('needs to assign an output')
        end
    end
    function out=toTable(obj)
        out=obj.cell2strTable(T,2,4,kW);
    end
    function out=end(obj,k,n)
        out=obj.numel();
    end
%% SUBS
    function varargout=subsref(obj,s)
        %if numel(obj.subs) < 1
        %S=struct('type','()','subs',[]);

        %if numel(s) > 1 && ismethod(obj,s(1).subs) && strcmp('()',s(2).type)
        %    s(2).subs{:}
        %    [varargout{1:nargout}]=builtin('subsref',obj.(s(1).subs),s(2));
        %else
        %if nargout == 1
        %    S.subs={1};
        %    [varargout{1:nargout}]=builtin('subsref',obj,S);
        %else
        %    S.subs=num2cell(repmat(1,nargout,1));
        %end
        %end

        switch s(1).type
        case '.'
            if ismethod(obj,s(1).subs)
                if numel(s) > 1 && strcmp(s(2).type,'()')
                    [varargout{1:nargout}]=feval(s(1).subs,obj,s(2).subs{:});

                    if nargout==1 && numel(s) > 2
                        [varargout{1:nargout}]=varargout{1}.subsref(s(3:end));
                    end
                elseif numel(s) > 1
                    out=obj.(s(1).subs);
                    [varargout{1:nargout}]=out.subsref(s(2:end));
                else
                    varargout{1}=obj.(s(1).subs);
                end
            elseif ismember(s(1).subs,{'vals','keys'})
                varargout{1}=obj.(s(1).subs);
            else
                error(['no method or property named ' s(1).subs]);
            end
        case {'{}','()'}
            [out,flds]=obj.subsref_ind([s(1).subs]);  % XXX SLOW
            if numel(flds)==0
                varargout{1}=out{:};
                return
            elseif numel(s(1).subs)==1 && ~iscell(obj.map(flds{1}))
                SS=struct('type','{}','subs',[]);
                SS.subs={1};
                out=builtin('subsref',out,SS);
            %elseif  numel(s(1))==1 && ~iscell(obj.map(flds{1}))
            end
            if strcmp(s(1).type,'()')
                out=dict(obj.bOrdered,flds,out);
            end
            if numel(s) > 1 && isa(out,'dict')
                %% RECURSION
                [varargout{1:nargout}]=out.subsref(s(2:end));
            elseif numel(s) > 1 && iscell(out) && numel(out)==1;
                [varargout{1:nargout}]=subsref(out{1},s(2:end));
            else
                if isempty(out) && iscell(out) && nargout==numel(out)
                    varargout{1}=[];
                elseif iscell(out) && nargout==numel(out)
                    varargout{:}=out{:};
                else
                    varargout{1}=out;
                end
            end

        case '()'
            error('dict: Use {} not ()');
        end
    end
end
methods(Access=protected)
    function [t,flds]=subsref_ind(obj,subs)
        if length(subs) < 1
            error('too many keys');
        end
        %fld=subs{1};

        K=obj.keys;
        if numel(subs) == 1 && numel(subs{1})==1 && isnumeric(subs{1}) && subs{1}==0
            t={obj.zeroval};
            flds=[];
            return
        elseif all(cellfun(@isnumeric,subs))
            flds=K([subs{:}]);
        else
            flds=subs;
        end
        t=cellfun(@(x) obj.map(x),flds,'UniformOutput',false)'; %% XXX SLOW
        %end
    end
    function out=getHeader(obj)
        n=Num.toStr(numel(keys(obj.map)));
        dim=[n char(215) '1' ];
        name = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
        out=['  ' dim ' ' name newline];
    end
    function out=getFooter(obj)
        if ~isempty(obj.zeroval)
            z={'_0_' obj.zeroval};
        else
            z=[];
        end
        T=[z; obj.keys obj.vals];
        kW=cellfun(@length,T);
        out=dict.cell2strTable(T,2,4,kW);
    end
    function out=displayEmptyObject(obj)
        if ~isempty(obj.zeroval)
            display([obj.getHeader() obj.getFooter]);
        else
            display([obj.getHeader() ]);
        end

    end
end
methods(Static,Access=private)
    function [txt,w,wo]=cell2strTable(C,nspace,indent,minSzs)
        %C={'bin','1','2'; 'val','1',''};
        %
        if ~exist('nspace','var') || isempty(nspace)
            nspace=2;
        end
        if ~exist('minSzs','var')
            minSzs=[];
        end

        txt=cell(size(C,1),1);
        col=zeros(1,size(C,1));
        r=zeros(1,size(C,1));
        for i = 1:size(C,2)
            flds=C(:,i);
            %ninds=cellfun(@isnumeric,flds);
            ninds=cellfun(@isnumeric,flds);
            linds=cellfun(@islogical,flds);
            oinds=cellfun(@isobject,flds) | cellfun(@iscell,flds);
            if all(ninds) && ~all(cellfun(@isempty,flds))

                flds=cellfun(@Num.toStr,flds,'UniformOutput',false);
                flds=split(flds,newline);
            else
                J=find(ninds);
                for jj = 1:length(J)
                    j=J(jj);
                    flds{j}=Num.toStr(flds{j});
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

            [txt{i},col(i),wo(i)]=dict.space_fun(flds,n,minSzs(i));
        end

        w=col;
        if isempty(txt)
            txt='';
            return
        end

        txt=join(join([txt{:}],2),newline);
        txt=txt{1};
        if exist('indent','var') && ~isempty(indent) && indent~=0
            indnt=repmat(' ',1,indent);
            txt=strrep([indnt txt],newline,[newline indnt]);
        end

    end
    function [flds,col,colO]=space_fun(flds,n,minSz)
        col=max(cellfun(@(x) size(x,2), flds));
        colO=col;
        if ~exist('minSz','var') || isempty(minSz)
            minSz=0;
        end
        n=n-1;
        n(n<0)=0;
        for i = 1:length(flds)
            tmp=minSz-col;
            if tmp > 0
                col=tmp+col;
            end

            space=repmat(' ',1,n+col-size(flds{i},2));
            flds{i}=[flds{i} space];
        end
    end

end
end
