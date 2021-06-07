classdef Var < handle
methods(Static)
    function [B,MB]=bytes(X)

        % function [B,MB]=bytes(X)
        %
        %   example call:
        %
        % returns the size of variable X in bytes and megabytes
        %
        % X:    input variable
        %%%%%%%%%%%%%%%%%%%%%%
        % B:    bytes
        % MB:   megabytes


        Xinfo = whos('X');

        B  = Xinfo.bytes;
        MB = B./1000000;
    end
    function bOut=isBuiltin(data)
        types={'double'...
            ,'single'...
            ,'int8'...
            ,'int16'...
            ,'int32'...
            ,'int64'...
            ,'uint8'...
            ,'uint16'...
            ,'uint32'...
            ,'uint64'...
            ,'char'...
            ,'cell'...
            ,'struct'...
            };
        bOut=contains(class(data),types);
    end
    function bInd=cmp(A,B,bNumAgnostic)
        if nargin <= 2
            bNumAgnostic=1;
        end
        tA=class(A);
        tB=class(B);
        if bNumAgnostic && isTypeNumeric(tA) && isTypeNumeric(tB)
            bInd=1;
        else
            bInd=strcmp(tA,tB);
        end
    end
    function ptr=pointer(thing)
        ptr=libpointer([class(thing) 'Ptr'],thing);
    end
    function val=ret(ptr)
        if isa(ptr,'lib.pointer')
            val=get(ptr);
            val=ptr.Value;
        else
            val=ptr;
        end
    end
    function [out] = is(varname)
        % function [out] = isvar(varname)
        % SLOW
        % Performs the function of exist('var',varname) && isempty(varname)
        % negate to check if a variable hasn't been defined yet.
        % example calls:
        %   A=[]; exist('A','var') && ~isempty(A)
        %   clear A; exist('A','var') && ~isempty(A)
        % CREATED BY DAVID WHITE

        if ~ischar(varname)
            error('isvar: make sure to put your variable name in quotations!')
        end

        try
            var=evalin('caller',varname);
        catch
            out=0;
        return
        end

        if isempty(var)
        out=0;
        else
        out=1;
        end

        %handle structs
        if isstruct(var)
            if isempty(fieldnames(var))
                out=0;
            else
                out=1;
            end
        end

        %handle cells
        if iscell(var)
            if all(cellfun(@(x) isempty(x),var))
                out=0;
            else
                out=1;
            end
        end
    end
    function out = getName(var)
    %RETURNS VARIABLE NAME AS STRING
        out = inputname(1);
    end
    function ise =  isInBase(var)
        ise = evalin( 'base',[ 'exist(''' var ''',''var'') == 1;' ]);
    end
    function var=tryVarFromBase(varName)
        if Var.isInBase(varName)
            var = evalin('base',[varName ';']);
        else
            var=[];
        end
    end
end
end
