function out=lji(list,n,bNewLineStart)
% list join indent
    if nargin < 2 || isempty(n)
        n=2;
    end
    if nargin < 3 || isempty(bNewLineStart)
        bNewLineStart=true;
    end
    str=strjoin(strcat({repmat(' ',1,n)},list),newline);
    if bNewLineStart
        out=[newline str];
    else
        out=str;
    end
end
