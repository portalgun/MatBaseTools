classdef reprint < handle
properties
    bb=''
    n
    cl
end
methods
    function obj=reprint()
        obj.cl=onCleanup(@() fprintf('\n'));
    end
    function print(obj,str)
        if nargin < 2
            str='';
        end
        fprintf([obj.bb str]);
        obj.n=length(str);
        obj.bb=repmat(char(8),1,obj.n);
    end
end
end
