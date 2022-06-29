classdef Toggler < handle
properties
    flds
    aliases

    bNest
    bTest
    bList
    bInc
    bMin
    bMax

    tests
    lists
    incs
    mins
    maxs

    cInds
    cVals

    Parent
end
methods
    function obj=Toggler(names,vals,cur,Parent)
        if nargin < 3
            cur=[];
        end
        if nargin < 4 && isempty(Parent)
            obj.Parent=Parent;
        end
        obj.parse_names(names);

        % TEST
        obj.tests=cell(size(vals));
        obj.bTest=cellfun(@(x) isa(x, 'function_handle'),vals);
        if any(obj.bTest)
            obj.tests(obj.bTest)=cellfun(@(x) x, vals(obj.bTest),'UniformOutput',false);
        end

        % LIST
        obj.lists=cell(size(vals));
        obj.bList=cellfun(@iscell,vals);
        if any(obj.bList)
            obj.lists(obj.bList)=cellfun(@(x) x, vals(obj.bList),'UniformOutput',false);
        end

        % INC
        obj.incs=zeros(size(vals));
        obj.bInc=cellfun(@(x) isnumeric(x) && numel(x)==3,vals);
        if any(obj.bInc)
            obj.incs(obj.bInc)=cellfun(@(x) x(2),vals(obj.bInc));
        end

        % MAX
        obj.maxs=inf(size(vals));
        obj.bMax=cellfun(@(x) isnumeric(x) && numel(x)>=2,vals);
        if any(obj.bMax)
            obj.maxs(obj.bInc)=cellfun(@(x) x(end),vals(obj.bMax));
        end

        % MIN
        obj.mins=inf(size(vals));
        obj.bMin=cellfun(@(x) isnumeric(x),vals);
        if any(obj.bMin)
            obj.mins(obj.bInc)=cellfun(@(x) x(1),vals(obj.bMin));
        end

        obj.cInds=zeros(size(vals));
        obj.cVals=cell(size(vals));

        bFilled=~cellfun(@isempty,cur);
        if isempty(cur)
            if any(obj.bList)
                obj.cInds(obj.bList)=1;
            elseif any(obj.bMin)
                obj.cVals(obj.bMin)=obj.mins(obj.bMin);
            end
        elseif isnumeric(cur)
            if any(obj.bList)
                obj.cInds(obj.bList)=cur(obj.bList);
            end
            if any(obj.bInc)
                [obj.cVals{obj.bInc}]=cur(obj.bInc);
            end
            if any(obj.bTest)
                [obj.cVals{obj.bTest}]=cur(obj.bTest);
            end
        elseif iscell(cur)
            if any(obj.bList)
                vls=vals;
                ind=false(size(obj.bList));
                ind(obj.bList)=cellfun(@(x) all(cellfun(@(y) Num.is(y) | islogical(y),x)),vls(obj.bList));
                if any(ind)
                    %vls{ind}=cell2mat(vls{ind});
                    vls(ind & obj.bList)=cellfun(@cell2mat, vls(ind & obj.bList),'UniformOutput',false);
                end

                if any(obj.bList & bFilled)
                    obj.cInds(obj.bList & bFilled)=cellfun(@list_fun, vls(obj.bList & bFilled) ,cur(obj.bList & bFilled));
                end
            end
            if any(obj.bInc)
                obj.cVals(obj.bInc)=cellfun(@(x) x,cur(obj.bInc),'UniformOutput',false);
            end
            if any(obj.bTest)
                obj.cVals(obj.bTest)=cellfun(@(x) x,cur(obj.bTest),'UniformOutput',false);
            end
        end
        function out=list_fun(v,c)
            out=find(ismember(v,c),1,'first');
            if isempty(out)
                out=0;
            end
        end
    end
    function [out,exitflag,msg]=inc(obj,name,n,bWrap,pos)
        [name,spl]=obj.get_split(name);
        exitflag=false;
        msg=[];
        if nargin < 2
            n=1;
        end
        if nargin < 4
            pos=1;
        end

        bNest=ismember(name,obj.aliases(obj.bNest));
        if ~isempty(obj.Parent) && bNest
            if nargin < 3
                bWrap=[];
            end
            obj.inc_parent_val_nest(I,spl,n,bWrap,pos);
            return
        end

        I=obj.get_I(name);
        if obj.bList(I)
            if nargin < 3 || isempty(bWrap)
                bWrap=true;
            end
            out=obj.inc_list(I,n,bWrap,pos);
        elseif obj.bInc(I)
            if nargin < 3 || isempty(bWrap)
                bWrap=false;
            end
            out=obj.inc_inds(I,n,bWrap,pos);
        elseif obj.bTest(I)
            out=[];
            exitflag=true;
            msg=[ 'Param ' name ' is not incrementable'];
            if nargout < 2
                error(msg);
            end
        end
        if ~isempty(obj.Parent)
            obj.set_parent_val(I,alias,out);
        end
    end
    function [exitflag,msg]=set(obj,name,val)
        [name,spl]=obj.get_split(name);
        I=obj.get_I(name);

        bNest=ismember(name,obj.aliases(obj.bNest));
        if ~isempty(obj.Parent) && bNest
            obj.set_parent_val_nest(I,spl,val);
            return
        end

        if ~any(I)
            error('invalid fld %s',name);
        end
        if obj.bTest(I)
            [exitflag,msg]=obj.set_test(I,val);
        elseif obj.bList(I)
            [exitflag,msg]=obj.set_list(I,val);
        else
            [exitflag,msg]=obj.set_inc(I,val);
        end
        if exitflag && nargout < 1
            error(msg);
        end
        if ~isempty(obj.Parent) && ~exitflag
            obj.set_parent_val(I,val);
        end
    end
    function [val,exitflag,msg]=get(name)
        msg=[];
        I=obj.get_I(name);
        exitflag=isempty(I);
        if exitflag
            msg=['''' name ''' is not a valid parameter' ];
            if nagout < 2
                error(msg)
            end
        end
        if obj.bList(I)
            val=obj.lists{obj.cInds(I)};
        else
            val=obj.cVals{I};
        end
    end
end
methods(Access=private)
    function [exitflag,msg]=set_test(obj,I,val)
        exitflag=true;
        msg=[];

        ME=[];
        try
            exitflag=~all(obj.tests{I}(val));
        catch ME
            msg=ME.message;
        end

        if exitflag
            if isempty(ME)
                msg='test returned false';
            end
            return
        end
        obj.cVals{I}=val;
    end
    function [exitflag,msg]=set_list(obj,I,val)
        exitflag=false;
        msg=[];
        ind=ismember(obj.lists{I},val);
        if ~any(ind)
            exitflag=true;
            msg='Value not in list';
            return
        end
        obj.cInds(I)=ind;
    end
    function [exitflag,msg]=set_inc(obj,I,val)
        exitflag=false;
        msg=[];
        if obj.bMin(I)
            exitflag=obj.mins(I) < val;
            if exitflag
                msg='Value smaller than minimum';
                return
            end
        end
        if obj.bMax(I)
            exitflag=obj.maxs(I) > val;
            if exitflag
                msg='Value larger than maximum';
                return
            end
        end
    end
    function out=inc_list(obj,I,n,bWrap,pos)
        ind=obj.cInds(I)+n;
        N=length(obj.lists{I});
        if bWrap && ( ind > N || ind < 1 )
            ind=mod(ind,N);
            if ind==0
                ind=N;
            end
        else
            if ind > N
                ind=N;
            elseif ind < 0
                ind=1;
            end
        end
        obj.cInds(I)=ind;
        out=obj.lists{I}{ind};
    end
    function out=inc_inds(obj,I,n,bWrap,pos)
        out=obj.cVals{I}(pos)+n*obj.incs(I);
        if bWrap && obj.bMax(I) && obj.bMin(I) && (out > obj.maxs(I) || out < obj.mins(I))
            out=obj.mins(I)+mod(out,obj.mins(I)-obj.maxs(I));
        elseif obj.bMax(I) && out > obj.maxs(I)
            out=obj.maxs(I);
        elseif obj.bMin(I) && out < obj.mins(I)
            out=obj.mins(I);
        end
        obj.cVals{I}(pos)=out;
    end
    function I=get_I(obj,name)
        alias=Toggler.parse_name(name);
        I=ismember(obj.aliases,alias);
    end
    function parse_names(obj,names)
        obj.bNest=startsWith(names,'@');
        names(obj.bNest)=strrep(names(obj.bNest),'@','');
        obj.flds=names;
        obj.aliases=cellfun(@obj.parse_name,names,'UniformOutput',false);
    end
    function set_parent_val(obj,I,val)
        if ismethod(obj.Parent,'set')
            obj.Parent.set(obj.flds{I},val);
        else
            setfield(obj.Parent,obj.flds{I}{:},val);
        end
    end
    function inc_parent_val_nest(obj,I,flds,n,bWrap,pos)
        dest=flds{1};
        if length(flds)==2
            flds=flds{2};
        else
            flds=flds(2:end);
        end
        if ismethod(obj.Parent.(dest),'inc')
            obj.Parent.(dest).inc(flds,n,pos);
        elseif isprop(obj.Parent.(dest),'Toggler')
            obj.Parent.(dest).Toggler.inc(flds,n,bWrap,pos);
        end
    end
    function set_parent_val_nest(obj,I,flds,val,pos)
        dest=flds{1};
        if length(flds)==2
            flds=flds{2};
        else
            flds=flds(2:end);
        end
        if ismethod(obj.Parent.(dest),'set')
            obj.Parent.(dest).set(flds,val);
        elseif isprop(obj.Parent.(dest),'Toggler')
            obj.Parent.(dest).Toggler.set(flds,val);
        end
    end
end
methods(Static,Access=private)
    function alias=parse_name(name)
        if ischar(name)
            alias=name;
            return
        end
        if iscell(name)
            alias=strjoin(name,'.');
        end
    end
    function [name,spl]=get_split(name)
        if contains(name,'.')
            spl=strsplit(name,'.');
            name=spl{1};
        elseif iscell(name)
            spl=name;
            name=spl{1};
        else
            spl=name;
        end
    end
end
end
