function out=RCtoBinary(szRC,RC)
    out=zeros(szRC);
    out(RC(:,1),RC(:,2))=1;
    out=logical(out);
end
