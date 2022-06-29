function out=tabify(str,nspaces)
    if nargin < 2
        nspaces=2;
    end
    s=repmat(' ',1,nspaces);
    out=[s strrep(str,newline,[newline s])];
end
