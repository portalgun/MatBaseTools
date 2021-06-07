classdef Arr < handle
methods(Static)
    function n=ndim(in)
        if (Vec.is(in) && numel(in) >= 1) || numel(in)==1
            n=1;
            return
        end
        n=numel(size(in));
    end
end
end
