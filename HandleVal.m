classdef HandleVal < handle
properties
    value
end
methods
    function obj=HandleVal(value)
        if nargin == 1
            obj.value=value;
        end
    end
    function set(obj,value)
        obj.value=value;
    end
    function set.value(obj,value)
        obj.value=value;
    end
    function value=get(obj)
        value=obj.value;
    end

end
end
