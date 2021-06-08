classdef Alph < handle
methods(Static)
    function newStr = lower(str);
    % function newStr = Str.Alph.Lower(str);
    %
    % example call:
    %              newStr=Str.Alph.Lower('aBcDEFG')
    % expected output:
    %              newStr
    %                    'abcdefg'
    % Works on cells too

        if iscell(str)
            newStr=cellfun(@(x) repfunc(x),str);
        else
            str=strrep(str,'A','a');
            str=strrep(str,'B','b');
            str=strrep(str,'C','c');
            str=strrep(str,'D','d');
            str=strrep(str,'E','e');
            str=strrep(str,'F','f');
            str=strrep(str,'G','g');
            str=strrep(str,'H','h');
            str=strrep(str,'I','i');
            str=strrep(str,'J','j');
            str=strrep(str,'K','k');
            str=strrep(str,'L','l');
            str=strrep(str,'M','m');
            str=strrep(str,'N','n');
            str=strrep(str,'O','o');
            str=strrep(str,'P','p');
            str=strrep(str,'Q','q');
            str=strrep(str,'R','r');
            str=strrep(str,'S','s');
            str=strrep(str,'T','t');
            str=strrep(str,'U','u');
            str=strrep(str,'V','v');
            str=strrep(str,'W','w');
            str=strrep(str,'X','x');
            str=strrep(str,'Y','y');
            str=strrep(str,'Z','z');
            newStr=str;

        end
    end
    function newStr = upper(str);
    % function newStr = Str.Alph.upper(str);
    %
    % example call:
    %              newStr=Str.Alph.Lower('aBcDEFG')
    % expected output:
    %              newStr
    %                    'abcdefg'
    % Works on cells too
        if iscell(str)
            newStr=cellfun(@(x) repfunc(x),str);
        else
            str=strrep(str,'a','A');
            str=strrep(str,'b','B');
            str=strrep(str,'c','C');
            str=strrep(str,'d','D');
            str=strrep(str,'e','E');
            str=strrep(str,'f','F');
            str=strrep(str,'g','G');
            str=strrep(str,'h','H');
            str=strrep(str,'i','I');
            str=strrep(str,'j','J');
            str=strrep(str,'k','K');
            str=strrep(str,'l','L');
            str=strrep(str,'m','M');
            str=strrep(str,'n','N');
            str=strrep(str,'o','O');
            str=strrep(str,'p','P');
            str=strrep(str,'q','Q');
            str=strrep(str,'r','R');
            str=strrep(str,'s','S');
            str=strrep(str,'t','T');
            str=strrep(str,'u','U');
            str=strrep(str,'v','V');
            str=strrep(str,'w','W');
            str=strrep(str,'x','X');
            str=strrep(str,'y','Y');
            str=strrep(str,'z','Z');
            newStr=str;
        end
    end
    function [new, ind] = sorti(old)
        %case insensitive sort
        [~,ind]=sort(Str.Alph.upper(old));
        new=old(ind);
    end

%% LOGIC
    function out = isXorY(str,X,Y)
         out=strcmp(str,X) || strcmp(str,Y);
    % XXX make ignore case
    end
    function out=isLower(in,key)
        out=ismember(in,Str.Alph.lowerA());

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end

    end
    function out=isUpper(in,key)
        out=ismember(in,Str.Alph.upperA());

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
   end
    function out=is(in,key)
        out=ismember(in,Str.Alph.A());

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
   end
   function out=isLorR(in,key)
        out = isequal(in,'L') || isequal (in,'R');
        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
   end
   function out=isLorRorB(in,key)
        out = isequal(in,'L') || isequal (in,'R') || isequal (in,'B');
        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
   end
%% SETS
    function A = lowerA()
        A=['abcdefghijklmnopqrstuvwxyz'];
        A=A(:);
    end
    function A = upperA()
        A=['ABCDEFGHIJKLMNOPQRSTUVWXYZ'];
        A=A(:);
    end

    function A = A()
        A=['abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'];
        A=A(:);
    end
end
end
