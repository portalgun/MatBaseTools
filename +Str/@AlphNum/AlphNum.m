classdef AlphNum < handle
properties(Constant)
    A=['abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ12345677890']
end
methods(Static)
    function out=is(in)
        out=ismember(in,Str.AlphNum.A);
    end
end
end
