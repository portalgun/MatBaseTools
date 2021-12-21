function OUT=horzcat(A,B,n)
    if ~iscell(A)
        A=strsplit(A,newline)';
    end
    if ~iscell(B)
        B=strsplit(B,newline)';
    end
    if nargin < 3
        n=2;
    end
    spc=repmat(' ',1,n);
    sA=size(A,1);
    sB=size(B,1);
    c=cell(abs(sA-sB),1);
    if sA > sB
        OUT=strjoin(strcat(A,{spc},[B; c]),newline);
    elseif sA < sB
        OUT=strjoin(strcat([A; c],{spc},B),newline);
    else
        OUT=strjoin(strcat(A,{spc},B),newline);
    end

end
