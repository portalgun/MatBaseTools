classdef Container < handle & matlab.mixin.CustomDisplay
properties
    val
end
methods(Access=protected)
    function out=getHeader(obj)
        dim = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
        name = [ class(obj.val) ' Container'];
        out=['  ' dim ' ' name newline];
    end
    function out=getFooter(obj)
        out=evalc('disp(obj.val)');
    end
    function propgrp=getPropertyGroups(obj)
        propgrp=matlab.mixin.util.PropertyGroup(struct());
    end
end
methods
    function obj=Container(thing)
        if nargin > 0
            obj.val=thing;
        end
    end
    function set(obj,thing)
        obj.val=thing;
    end
    function out=get(obj)
        out=obj.val;
    end

%% OVERLOAD
    function varargout=subsref(obj,s)
        if strcmp(s(1).type,'.') && ( ismember_cell(s(1).subs,{'get','set','ndims','size','fieldnames','rmfield','isprop','isfield','ismethod','isa','class'}) )
            [varargout{1:nargout}] = builtin('subsref',obj,s);
        else
            [varargout{1:nargout}]=builtin('subsref',obj.val,s);
        end
    end
    function obj=subsasgn(obj,s,val)
        if strcmp(s(1).type,'.') && strcmp(s(1).subs,'Val')
            obj.valRep(val);
        else
            obj.val=builtin('subsasgn',obj.val,s,val);
        end
    end
    function out=ndims(obj)
        out=ndims(obj.val);
    end
    function out=size(obj)
        out=size(obj.val);
    end
    function out=fieldnames(obj)
        out=fieldnames(obj.val);
    end
    function obj=rmfield(obj,args)
        obj.val=rmfield(obj.val,args);
    end
    function out=isprop(obj,p)
        out=isprop(obj.val,p);
    end
    function out=isfield(obj,fld)
        out=isfield(obj.val,fld);
    end
    function out=ismethod(obj,m)
        out=ismethod(obj.val,m);
    end
%% TODO change if builtin
    function out=isa(obj,m)
        out=(isobject(obj.val) && isa(obj.val,m)) || strcmp(m,'Container');
    end
    function out=class(obj)
        if isobject(obj.val)
            out=class(obj.val);
        else
            out='Container';
        end
    end
%%% single
%    function out=class(obj)
%        out=class(obj.val);
%    end
%    function out=log(obj)
%        out=log(obj.val);
%    end
%    function out=abs(obj)
%        out=abs(obj.val);
%    end
%    function out=sign(obj)
%        out=sign(obj.val);
%    end
%    function out=ceil(obj)
%        out=ceil(obj.val);
%    end
%    function out=floor(obj,varargin{:})
%        out=floor(obj.val);
%    end
%    function out=fix(obj)
%        out=ceil(obj.val);
%    end
%%% multiple variable
%    function out=round(obj)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=mod(obj)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=prod(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=sum(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=dot(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=cat(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=vertcat(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=horzcat(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=plus(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=minus(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=divide(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
%    function out=multiply(varargin)
%        s=dbstack;
%        name=strrep(s.name,'Container.','');
%
%        ind=cellfun(@(x) isa(x,'Container'),varargin);
%        obj=varargin{ind};
%        varargin{ind}=obj.val;
%
%        out=builtin(name,varargin{:});
%    end
end
end
