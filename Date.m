classdef Date < handle
methods(Static)
    function out=timeFilStr()
        out=char(datetime('now','Format','yyyy-MM-dd-HH-mm'));
    end
    function ind = newest(C)
        lind=zeros(size(C));
        ind=[];
        for i = 1:length(C)
            if isempty(C{i})
                continue
            elseif ~exist('cur','var') || isempty(cur)
                curtmp=datetime(datestr(C{i}));
                if isempty(curtmp)
                    continue
                end
                ind=i;
                cur=curtmp;
                continue
            end

            new=datetime(datestr(C{i}));
            if isempty(new)
                continue
            end
            if new > curtmp
                ind=i;
            end
        end
    end
    function unix()
    end
    function d=unix2human_file(t)
       % d = datetime(t,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss.SSSSSSSSS');
         %d = datetime(t,'ConvertFrom','epochtime','TicksPerSecond',1e3,'Format','dd-MMM-yyyy HH:mm:ss.SSS')
         d = char(datetime(t,'ConvertFrom','epochtime','Format','yy-MM-dd_HH:mm'));
    end
end
end
