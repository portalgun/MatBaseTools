function txt=cell2strtable(C,nspace)
    %C={'bin','1','2'; 'val','1',''};
    %
    if ~exist('nspace','var') || isempty(nspace)
        nspace=2;
    end

    txt=cell(size(C,1),1);
    for i = 1:size(C,2)
        flds=C(:,i);
        if all(cellfun(@isnumeric,flds)) && ~all(cellfun(@isempty,flds))
            flds={Num.toStr(vertcat(flds{:}))};
        end
        if i==size(C,2)
            n=0;
        else
            n=nspace;
        end
        txt{i}=space_fun(flds,n);
    end
    txt=join(join([txt{:}],2),newline);
    txt=txt{1};

end
function flds=space_fun(flds,n)
    col=max(cellfun(@(x) size(x,2), flds))+n;
    for i = 1:length(flds)
        space=repmat(' ',1,col-size(flds{i},2));
        flds{i}=[flds{i} space];
    end
end
