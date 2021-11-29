classdef Obj < handle
methods(Static)
    function newObj = copy(obj)
        try
                % R2010b or newer - directly in memory (faster)
                objByteArray = getByteStreamFromArray(obj);
                newObj = getArrayFromByteStream(objByteArray);
        catch
                % R2010a or earlier - serialize via temp file (slower)
                fname = [tempname '.mat'];
                save(fname, 'obj');
                newObj = load(fname);
                newObj = newObj.obj;
                delete(fname);
        end
    end
    function b = copy_old(a)
        b = eval(class(a));  %create default object of the same class as a. one valid use of eval
        prps=Obj.props(a);
        for i =  1:length(prps)  %copy all public properties
            p=prps{i};
            b.(p) = a.(p);
            %try   %may fail if property is read-only
            %   b.(p) = a.(p);
            %catch
            %   warning('failed to copy property: %s', p);
            %end
        end
    end
    function hash=hash(obj,rmflds,rmfldsStartsWith)
        if ~exist('rmflds','var')
            rmflds=[];
        end
        if ~exist('rmfldsStartsWith','var')
            rmfldsStartsWith=[];
        end

        S=obj2structPublic(obj);
        flds=fieldnames(S);

        if ~isempty(rmfldsStartsWith)
            S=structRmFldsStartsWth(S,rmfldsStartsWith);
        end
        if ~isempty(rmflds)
            S=structRmFlds(S,rmflds);
        end


        hash=DataHash(S);
    end
    function obj2=cast(obj1,obj2)
        if ischar(obj2)
            obj2=eval([obj2 '();']);
        elseif ~isobject(obj2)
            obj2=cast(obj1,obj2);
            return
        end
        s=Obj.struct(obj1,false);
        flds=fieldnames(s);
        for i = 1:length(flds)
            obj2.(flds{i})=s.(flds{i});
        end
    end
    function S = struct(obj,bRecursive)
    % S = obj2struct(obj)
    % see get_regressors in EXP
        if ~exist('bRecursive','var') || isempty(bRecursive)
            bRecursive=0;
        end
        warning('off','MATLAB:structOnObject');
        S=struct(obj);
        warning('on','MATLAB:structOnObject');
        if bRecursive
            flds=fieldnames(S);
            for i = 1:length(flds)
                fld=flds{i};
                if isobject(S.(fld))
                    S.(fld)=Obj.struct(S.(fld),1);
                end
            end
        end
    end
    function S=pubStruct(obj)
    %function S=obj2structPublic(obj)
        fldsPub=Obj.props(obj);

        warning('off','MATLAB:structOnObject');
        S=struct(obj);
        warning('on','MATLAB:structOnObject');
        flds=fieldnames(S);
        for i = 1:length(flds)
            fld=flds{i};
            if ~ismember(fld,fldsPub)
                S=rmfield(S,fld);
            end
        end
    end
    function saveParts(obj,fname,flds)
        if ~exist('flds','var')
            flds=fieldnames(obj);
        end
        for i =1:length(flds)
            fld=flds{i};
            eval([fld '=obj.(fld);']);
        end
        save(fname,flds{:});
    end
    function out=isSub(clss,superclss)
        out=ismember(superclss,superclasses(clss));
    end
    function objSNK=adoptProps(objSRC,objSNK,ignore)
        if ~exist('ignore','var')
            ignore={};
        end
        props=fieldnames(objSRC);
        for i = 1:length(props)
            prop=props{i};
            try %if isprop(objSRC,prop) &&  isprop(objSNK,prop) && ~ismember(prop,ignore)
                objSNK.(prop)=objSRC.(prop);
            end
        end
    end
    function out=properties(in);
        out=Class.props(in);
    end
    function out=props(in)
        out=properties(in);
    end
    function out=methods(in)
        out=Class.meths(in);
    end
    function out=meths(in)
        out=methods(in);
    end
    function out=isMeth(cls,meth)
        if ischar(in)
            meths=methods(cls);
            out=ismember(meth,methds);
        else
            out=ismethod(cls,meth);
        end
    end
    function out=isProp(cls,prp)
        if ischar(cls)
            prps=properties(cls);
            out=ismember(prp,prps);
        else
            out=isprop(cls,prp);
        end

    end






end
end
