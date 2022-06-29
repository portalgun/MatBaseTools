classdef PStruct < handle & matlab.mixin.CustomDisplay
properties(Hidden)
    S=struct()
end
methods
    function obj=PStruct(varargin)
        if nargin < 1
            return
        end
        if nargin == 1 && isstruct(varargin{1})
            obj.S=obj.recurse(varargin{1});
        end
        obj.S=obj.recurse(struct(varargin{:}));
    end
    function obj=subsasgn(obj,s,val)
        switch s(1).type
        case '.'
            if builtin('isstruct',val)
                val=obj.recurse(val);
            end
            obj.S=builtin('subsasgn',obj.S,s,val);
        end
    end
    function flds=fieldnames(obj)
        flds=fieldnames(obj.S);
    end
    function out=subsref(obj,s)
        flag=false;
        switch s(1).type
        case {'.','()'}
            if ismethod(obj,s(1).subs)
                str=['PStruct>PStruct>.' s(1).subs];
                n=nargout(str);
                if n==-1
                    n=nargout;
                end
                [varargout{1:n}] = builtin('subsref',obj,s);
                flag=true;
            end
        case '{}'
            if s(1).subs{1}==':';
                out=obj.unrecurse();
                flag=true;
            end
        end
        if ~flag
            o=builtin('subsref',obj.S,s(1));
            if isstruct(o)
                out=PStruct();
                out.S=o;
            else
                out=o;
            end
        end
        if length(s) > 1
            out=subsref(out,s(2:end));
        end
    end
    function out=size(obj)
        out=obj.size(obj.S);
    end
    function out=isstruct(obj)
        out=true;
    end
end
methods(Access=protected)
    function S=unrecurse(obj)
        S=ur_fun(obj);
        function S=ur_fun(P)
            S=structfun(@fld_fun,P.S,'UniformOutput',false);
        end
        function out=fld_fun(s)
            if isa(s,'PStruct')
                s=ur_fun(s);
                out=s.S;
            else
                out=s;
            end
        end
    end
    function S=recurse(obj,S)
        S=r_fun(S);
        function S=r_fun(S)
            S=structfun(@fld_fun,S,'UniformOutput',false);
        end
        function out=fld_fun(s)
            if builtin('isstruct',S)
                s=r_fun(s);
                out=PStruct();
                out.S=s;
            else
                out=s;
            end
        end
    end
    function out=getHeader(obj)
        dim = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
        name = 'Pstruct';
        out=['  ' dim ' ' name newline];
    end
    function out=getFooter(obj)
        out=evalc('disp(obj.S)');
    end
end
end
