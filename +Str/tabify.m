function out=tabify(str,nspaces)
    if nargin < 2
        nspaces=2;
    end
    s=repmat(' ',1,nspaces);
    out=['  ' strrep(str,newline,[newline '  '])];
end
