classdef Arr < handle
methods(Static)
    function n=ndim(in)
        if (Vec.is(in) && numel(in) >= 1) || numel(in)==1
            n=1;
            return
        end
        n=numel(size(in));
    end
    function [out,IND]=nanSortRows(A)
        indNan=isnan(A);
        inds=find(~indNan);
        [~,order]=sortrows(A(~indNan));
        out=nan(size(A));
        IND=inds(order);
        out(IND)=A(~indNan);
    end
    function out= mode(in)
        %in={'abc','def','abc','efg','efg','efg','abc','def'};
        [t,~,ind]=unique(in);
        counts=hist(ind,1:numel(t));
        indind=find(counts==max(counts));
        out=t(indind);

    end
    function [ANew,BNew]=sortBToNearestPlaceByA(A,B,Ideal,IszRC)
        N=prod(IszRC);
        rA=round(A);
        AInds=Sub.toInd(rA,IszRC);
        IdealInds=transpose(1:N);

        
        D=sqrt(sum(A(:,2)-rA(:,2)).^2);

        % OUT OF RANGE GETS PUT INTO LAST BIN
        badInds=isnan(AInds) | AInds > N | AInds < 1;
        AInds(badInds)=[];
        A(badInds,:)=[];
        B(badInds,:)=[];

        Bins=1:N;
        Edges=[0:N]+0.5;

        % slots where each AInd should go
        binInds=discretize(AInds,Edges);

        %[binInds]=sort(binInds);
        hc=histcounts(binInds,Edges);
        maxc=max(hc);


        ANew=nan(N,2,1);
        BNew=nan(N,2,1);
        %for i = 1:5
        %gdInd=ismember(binInds,Bins(hc==1));

        method=1;
        if method==1
            gdInd=ismember(binInds,Bins(hc<5));
            gdBins=binInds(gdInd);

            ANew(gdBins,:,:)=A(gdInd,:);
            BNew(gdBins,:,:)=B(gdInd,:);
        elseif method==2
            gdInd=ismember(binInds,Bins(hc==1));
            gdBins=binInds(gdInd);
            ANew(gdBins,:,:)=A(gdInd,:);


            BinPool=Bins(hc>1);
            uBinPool=unique(BinPool);

            % TODO
            %%  SLOWW
            for i=1:length(uBinPool)
                gdInds=find(ismember(binInds,uBinPool(i)));
                gdBins=binInds(gdInds(1));

                d=abs(round(A(gdInds,2))-A(gdInds,2));
                sel=d==min(d);
                Anew(gdBins,:)=A(gdInds(sel),:);
                Bnew(gdBins,:)=B(gdInds(sel),:);
            end

        end


    end
end
end
