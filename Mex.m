classdef Mex < handle
methods(Static)
    function han=get_ext()
        if ismac()
            han='.mexmaci64';
        elseif ispc()
            han='.mexw64';
        else
            han='.mexa64';
        end
    end
    function out=iscompiled(srcFile)
        ext=Mex.get_ext();
        [dire,name]=Fil.parts(srcFile);
        fname=[name ext];
        out=~isempty(which(fname));
    end
end
end
