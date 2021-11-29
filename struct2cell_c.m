classdef struct2cell_c < handle
properties(Access=?Struct)
    flds=cell(0,1);
    vals=cell(0,1);
end
methods(Access=?Struct)
    function obj=struct2cell_c(in)
        obj.fun(in,{});
    end
    function obj=fun(obj,in,parents)
        flds=fieldnames(in);
        for i = 1:length(flds)
            fld=flds{i};
            if isstruct(in.(fld))
                P=[parents fld];
                obj.fun(in.(fld),P);
            else
                obj.flds{end+1,:}=[parents fld];
                obj.vals{end+1,:}=in.(fld);
            end
        end
    end

end
end
