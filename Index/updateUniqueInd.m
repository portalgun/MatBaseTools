function out=updateUniqueInd(in,nUnq)
    %in=   [1 2 3 3 4 5 5 6 3 3 3 1 7]';
    %nUnq= [0 1 1 0 0 1 0 0 0 1 0 0 0]';
    %Eout= [1 2 3 4 6 7 8 9 4 5 4 1 10]';
    %Eout= [1 2 3 4 5 6 7 8 4 9 4 1 10]';

    X=unique(in);
    [count]=hist(in,X);
    count=count==1;
    % get uniqu ind
    bUnq=zeros(size(in));
    for i = 1:length(X)
        bUnq(in==X(i))=count(i);
    end
    %bUnq= [0 1 0 0 1 0 0 1 0 0 1];
    bInd=~bUnq & nUnq;

    [~,inde]=sort(in);
    [~,rinde]=sort(inde);

    [ins,ind]=sortrows([in nUnq]);
    [~,rind]=sort(ind);
    out=ins(:,1)+cumsum(bInd(ind));
    out=out(rind)
    [~,~,ind]=unique(out,'stable')

end
