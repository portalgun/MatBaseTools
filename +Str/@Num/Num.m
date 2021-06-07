classdef Num < handle
methods(Static)
%% LOGIC
    function out=is(in,key)
        out=ismember(in,Str.Num.A);

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
    function out=isMat(in)
        out=ismember(in,Str.Num.matA);

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
    function out=isInt(in)
        out=ismember(in,Str.Num.intA);

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
    function out=isReal(in)
        out=ismember(in,Str.Num.realA);

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
    function out=isImag(in)
        out=ismember(in,Str.Num.imagA) && ismember(in,'i');

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
%% SETS
    function out=intA()
        out=['12345677890'];
        out=out(:);
    end
    function out=negA()
        out=['12345677890-'];
        out=out(:);
    end
    function out=realA()
        out=['12345677890.-+'];
        out=out(:);
    end
    function out=imagA()
        out=['i12345677890.-+'];
        out=out(:);
    end
    function out=A()
        out=Str.Num.realA();
    end
    function out=matA()
        out=['i12345677890.-,[] '];
        out=out(:);
    end
end
end
