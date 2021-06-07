function Xnew=appendColIsz(X,col)
% append col to X ignoring  column length (extending with nans)
    nC=size(col,1);
    oC=size(col,3);
    nX=size(X,1);
    mX=size(X,2);
    oX=size(X,3);
    if isempty(X)
        Xnew=col;
        return
    elseif nC > nX
        % fill mat with nans to fit column size
        nN=nC-nX;
        if oX > 1
            N=nan(nN,mX,oX);
        else
            N=nan(nN,mX);
        end

        X=[X; N];
    elseif nC < nX
        % fill col with nans
        nN=nX-nC;
        if oC > 1
            N=nan(nN,1,oC);
        else
            N=nan(nN,1);
        end
        col=[col; N];
    end
    Xnew=[X col];
end
