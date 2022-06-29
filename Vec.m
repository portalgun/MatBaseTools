classdef Vec < handle
methods(Static)
    %function out=is(in)
    %    out=Vec.isCol(in) || Vec.isRow(in)
    %end
    function out = is(in)
        n=sum(size(in) ~= 1);
        out = n==1 || n==0;
    end
    function out = isN(in,n)
        if n == 1
            out=isvector(in) && ize(in,2)==1;
            return
        elseif n ==2
            out=isvector(in) && size(in,1)==1;
            return
        end
        sz=size(in);
        out=ndims(in)==n && all(sz(1:n)==1);
    end
    function out = isCol(in)
        out=isvector(in) && ~isrow(in);
    end
    function out = isRow(in)
        out=isvector(in) && isrow(in);
    end
    function out = col(in)
        if isrow(in) || ~isvector(in)
            out=in(:);
        else
            out=in;
        end
    end
    function out = row(in)
        if ~isrow(in)
            if isvector(in)
                out=transpose(in);
            else
                out=transpose(in(:));
            end
        else
            out=in;
        end
    end
    function V=insert(V,inds,vals)
        if Vec.isCol(V)
            Vec.insert_col(V,inds,vals);
        elseif Vec.isRow(V)
            Vec.insert_row(V,inds,vals);
        end

    end
end
methods(Static, Access=private)
    function V = insert_col(V,inds,vals)
        if length(inds)==1
            inds=Vec.col(inds);
            vals=Vec.col(vals);
            V=[V(1:inds-1,:); vals(1,:); V(inds:end,:)];
        else
            for i = 1:length(inds)
                V=[V(:,1:inds(i)-1,:); vals(i,:); V(inds(i):end,:)];
            end
        end
    end
    function V = insert_row(V,inds,vals)
        inds=Vec.row(inds);
        vals=Vec.row(vals);
        if length(inds)==1
            V=[V(:,1:inds-1), vals(:,1), V(:,inds:end)];
        else
            for i = 1:length(inds)
                V=[V(:,1:inds(i)-1), vals(:,i), V(:,inds(i):end)];
            end
        end
    end
end
end
