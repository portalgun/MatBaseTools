classdef Index < handle
methods(Static)
    function sub=toSub(ind,IszRC)
        sub=[mod(ind-1,IszRC(1))+1 ceil(ind./IszRC(1))];
    end
end
end
