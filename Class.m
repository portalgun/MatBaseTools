classdef Class < handle
methods(Static)
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
        if ischar(in)
            prps=properties(cls);
            out=ismember(prp,prps);
        else
            out=isprop(cls,prp);
        end

    end
end
end
