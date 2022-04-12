classdef ArgsTest < handle
methods(Static)
    function test=parseTest(test)
        if isempty(test)
            test=@(x) Args.istrue;
            return
        elseif isa(test,'function_handle')
            return
        end
        % is.(class)
        test=regexprep(test,'^is\.(.[A-Za-z0-9]+)','isa(x,''$1'')');
        test=regexprep(test,'^(is)?([Cc]harcell|[cC]ellstruct|[Bb]inary|[iI]nt|[dD]ouble|[sS]ingle)','Args.is$2');
        test=regexprep(test,'^(struct|char|numeric|logical|cell)','is$1');
        flags=strsplit(test,'_');
        fInds=cellfun(@(x) Str.RE.ismatch(x,'^(a|e|([0-9]+(x[0-9]+)+)|^[0-9]+)$'),flags);
        if sum(fInds)==0
            if ~startsWith(test,'@')
                test=[ '@' test ];
            end
            test=str2func(test);
            return
        end
        fInds=~logical(cumprod(~fInds));
        test=strjoin(flags(~fInds));
        if ismethod('Args',test)
            test=['Args.' test];;
        end
        if ~endsWith(test,')')
            test=[test '(x)'];
        end
        flags=flags(fInds);

        for i = 1:length(flags)
            flag=flags{i};
            switch flag
                case 'i'
                    test=['ismember(x,' test ')'];
                case 'e'
                    test=['isempty(x)  || (' test  ')'];
                case 'a'
                    test=['all(' test  ')'];
                otherwise
                    if Str.Num.isInt(flag)
                        test=['numel(x)==' flag ' && (' test ')'];
                    elseif Str.RE.ismatch(flag,'^[0-9x]+$')
                        flag=['[' Num.toStr(strrep(flag,'x',' ')) ']'];
                        test=['isequal(size(x),' flag ')  && (' test ')'];
                    end
            end
        end

        if ~startsWith(test,'@') && ~isempty(flags)
            test=[ '@(x) ' test ];
        elseif ~startsWith(test,'@')
            test=[ '@' test];
        end
        test=str2func(test);
    end
%%
    function str=val2str(val)
        sz=Num.toSizeStr(size(val));
        str=[ class(val) ' ' sz ];

        %if ~iscell(val) && ~isstruct(val) && numel(val)
        %    if isnumeric(val) && numel < 200
        %        str=[str newline Num.toStr(val)];
        %    end
        %end

    end
%%
    function out=isCharList(in)
        out=ischarlist(in);
    end
    function out=ischarlist(in)
        out=ischar(in) || Args.ischarCell(in);
    end
    function out=isCharCell(in)
        out=Args.ischarcell(in);
    end
    function out=ischarcell(in)
        if ~iscell(in)
            out=false;
            return
        end
        try
            out=all(cellfun(@(x) ischar(x) & ~isempty(x),in),'all');
        catch
            out=all(all(cellfun(@(x) ischar(x) & ~isempty(x),in)));
        end
    end
    function out=isCellStruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
    end
    function out=iscellstruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
    end
    function isnormal(in)
        out=isnumeric(in) && in <= 1 && in >=0;
    end
    function out=isNormal(in)
        out=Arg.isnormal(in);
    end
    function out=isOptions(in)
        out=isoptions(in);
    end
    function out=isoptions(in)
        out=ismember(class(in),{'dict','struct'});
    end
    function out =isBinary(in)
        out=Args.isbinary(in);
    end
    function out =isbinary(in)
        if islogical(in)
            out=true;
        elseif ~isnumeric(in)
            out=false;
            return
        end
        out=isequal(in,1) | isequal(in,0);

    end
    function out =isInt(in)
        out=isint(in);
    end
    function out = isint(in)
        if ~isnumeric(in)
            out=0;
            return
        end
        out=~(mod(in,1));
    end
    function out=isDouble(in)
        out=Args.isDouble(in);
    end
    function out = isdouble(in)
        out=isa(in,'double');
    end
    function out=isSingle(in)
        out=Args.issingle(in);
    end
    function out = issingle(in)
        out=isa(in,'single');
    end
    function out= isdict(in)
        out=isa(in,'dict');
    end
    function out= isTrue(varargin)
        out=true;
    end
    function out= istrue(varargin)
        out=true;
    end
end
end
