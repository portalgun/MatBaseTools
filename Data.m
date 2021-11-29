classdef Data < handle
methods(Static)
    function global(name,var)

        str=['global ' name ' = var;' ];
        eval(str);
        evalin('caller',str);
        evalin('base',str);
    end
    function varargout=load(fname,baseLoadVarName)
        if nargout < 1
            for i =1:length(flds)
                assignin('caller',flds{i},S.(flds{i}));
            end
        else
            varargout{1}=S;
        end
    end

    function clearBaseLoad(varName)
        endStr='__baseLoad';
        if ~endsWith(varName,endStr)
            varName=[varName endStr];
        end
        evalin('base',['clear ' var]);
    end
    function clearBaseLoadAll()
        re='.*__baseLoad';
        vars=Data.RE(re,'base');
        for i = 1:length(vars)
            evalin('base',['clear ' vars{i}]);
        end
    end
    function out=RE(re,workspace)
        if nargin < 2
            workspace='base';
        end
        W = evalin(workspace,'whos');
        names=transpose({W(:).name});
        ind=Str.RE.ismatch(names,re);
        out=names(ind);
    end
    function baseSave(var,varName)
        endStr='__baseLoad';
        if ~endsWith(varName,endStr)
            varName=[varName endStr];
        end
        assignin('base',varName,var);
    end
    function varargout=baseLoad(fname,varName)
        endStr='__baseLoad';
        if ~endsWith(varName,endStr)
            varName=[varName endStr];
        end
        if Data.isInBase(varName)
            S=Data.fromBase(varName);
        else
            S=load(fname);
            assignin('base',varName,S);
        end
        flds=fieldnames(S);
        if nargout < 1
            for i =1:length(flds)
                assignin('caller',flds{i},S.(flds{i}));
            end
        else
            varargout{1}=S;
        end
    end
    function out=isInBase(varName)
        W = evalin('base','whos');
        out = ismember('A',[W(:).name]);
    end
    function var=fromBase(varName)
        var = evalin('base', varName);
    end

end
end
