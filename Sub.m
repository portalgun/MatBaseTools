classdef Sub < handle
methods(Static)
    function inds = toInd(sub,IszRC)
        inds=sub(:,1) + (sub(:,2)-1)*IszRC(1);
        %inds=sub(:,1) + (sub(:,2))*IszRC(1);
        %inds=sub(:,2) + (sub(:,1)-1)*IszRC(2);
        %dk
    end
end
end
