classdef Fld < handle
%% TODO Num
properties(Constant)
      K={'@','__a'; '\','__b'; ',', '__c'; '.','__d';'=','__e';'f','__f' ;'*','__g';'#','__h';'(','__i';')','__j'; '''', '__k'; '"', '__l';'-','__m';'&','__n';'+','__p' ;'?','__q';'$','__s';' ','__t';'[','__u';']','__v';'!','__x';'{','__y';'}','__z';'_','_';'','o__'};
      A=['abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ12345677890_']
end
methods(Static)
    function out=str(in)
        if iscell(in)
            out=cellfun(@Str.Fld.strFun,in);
        else
            out=Str.Fld.strFun(in);
        end
    end
    function out=isValid(in)
        out=Str.Alph.is(in(1)) && all(ismember(in,Str.Fld.A));
    end
end
methods(Static, Access=private)
    function out=fldFun(in)
        defs=Str.Fld.K;
        mp=containers.Map(defs(:,1),defs(:,2));
        out='';
        if ~ismember(in(1),Str.Alph.A)
            out='o__';
        end
        if isnumeric(in)
            in=num2str(in);
        end
        for i = 1:length(in)
            if Str.AlphNum.is(in(i))
                out=[out in(i)];
            else
                out=[out mp(in(i))];
            end
        end
    end
    function out=strFun(in)
        defs=Str.Fld.K;
        mp=containers.Map(defs(:,2),defs(:,1));
        out='';
        if startsWith(in,'o__')
            i=4;
        else
            i=1
        end
        while i <= length(in)

            c=in(i:i+2);
            if Str.AlphNum.is(in(i)) || strcmp(c,'___') || c(2)~='_'
                out=[out in(i)];
                i=i+1;
            else
                out=[out mp(c)];
                i=i+3;
            end
        end
    end
end
methods(Static, Hidden)
    function out=fld(in)
        if iscell(in)
            out=cellfun(@Str.Fld.fldFun,in);
        else
            out=Str.Fld.fldFun(in);
        end
    end
end
end
