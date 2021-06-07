classdef Obj < handle
methods(Static)
    function b = copy(a)
        b = eval(class(a));  %create default object of the same class as a. one valid use of eval
        prps=props(a);
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
                    S.(fld)=obj2struct(S.(fld),1);
                end
            end
        end
    end
    function S=pubStruct(obj)
    %function S=obj2structPublic(obj)
        fldsPub=props(obj);

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






end
end
