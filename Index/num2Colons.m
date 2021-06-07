function col=num2Colons(ndims,notColInd,notColVal)
    if ndims==1 && exist('notColVal','var') && ~isempty(notColVal) && ~isnan(notColVal)
        col=num2str(notColVal);
        return
    elseif ndims==1
        col=':';
        return
    elseif ~exist('notColInd','var') || isempty(notColInd) || ~exist('notColVal','var') || isempty(notColVal)
        col=repmat(':,',1,ndims);
        col(end)=[];
        return
    elseif notColInd>ndims
        error('Selected subscript is greater than number of dimensions')
    end

    if notColInd==1
        z=['1,' repmat(':,',1,ndims-notColInd)];
    elseif notColVal==ndims
        z=[repmat(':,',1,notColInd-1) '1,' ];
    else
        z=[repmat(':,',1,notColInd-1) '1,' repmat(':,',1,ndims-notColInd)];
    end
    col=strrep(z,'1',num2str(notColVal));
    col(end)=[];
