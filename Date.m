classdef Date < handle
methods
    function ind = newest(C)
        lind=zeros(size(C));
        ind=[];
        for i = 1:length(C)
            if isempty(C{i})
                continue
            elseif ~exist('cur','var') || isempty(cur)
                curtmp=datestr(C{i});
                if isempty(curtmp)
                    continue
                end
                ind=i;
                cur=curtmp;
                continue
            end

            new=datestr(C{i});
            if isempty(new)
                continue
            end
            if new > curtmp
                ind=i;
            end
        end
    end
end
end
