function str=indent(str,nSpaces)
    ind=repmat(' ',1,nSpaces);
    bFlag=0;
    if ~startsWith(str,newline)
        bFlag=1;
        str=[newline str];
    end

    EndCount=0;
    while endsWith(str,newline)
        EndCount=EndCount+1;
        str=str(1:end-1);
    end
    str=strrep(str,newline,[newline ind]);

    if EndCount > 0
        n=repmat(newline,1,EndCount);
        str=[str n];
    end
    if bFlag
        str=str(3:end);
    end
    str=[' ' str];
end
