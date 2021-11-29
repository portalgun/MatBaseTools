classdef Num < handle
methods(Static)
    function out=ceilFix(in)
        out=ceil(abs(in)).*sign(in);
    end
    function n =nSig(x)

        if any( ~isnumeric(x) | ~isfinite(x) | isa(x,'uint64') )
            error('Need any finite numeric type except uint64');
        end
        if numel(x) > 1
            n=arrayfun(@Num.sigfun,x);
        else
            n=Num.sigfun(x);
        end

    end
    function out=mag(in)
        out=10.^floor(log10(abs(in)));
    end
    function out=sciMag(in)
        if Num.isInt(in)
            in=double(in);
        end
        out=floor(log10(abs(in)));
    end
    function [float,exp]=toSci(in)
        float=in/Num.mag(in);
        exp=Num.sciMag(in);

        if isnan(float)
            float=0;
            exp=0;
        end

        %new=eval([num2str(float) 'e' num2str(exp) ';' ]);
        %in==new
    end
    function out=toSciStr(in)
        [float,exp]=Num.toSci(in);
        if float==0 & exp==0
            out='0';
        end
        out=[num2str(float) 'x10^' num2str(exp)];
    end
    function n =nSigDec(in)
        n=Num.nSig(in);
        intg=floor(log10(abs(in))+1);

        n=n-intg;
        n(n < 0)=0;
    end
    function out=minMax(in)
        out=[min(in(:)) max(in(:))];
    end
    function out=isType(in,key)
        if ~char(in)
            error('isType takes a type string. Maybe use ''is'' instead');
        end
        out=ismember(in, Num.typeSet());

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end
    end
    function out=is(in,key)
        if ~isnumeric(in)
            out=0;
            return
        end
        out=ismember(class(in), Num.typeSet());

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end

    end
    function out =isBinary(in,key)
        if islogical(in)
            out=true;
        elseif ~isnumeric(in)
            out=false;
            return
        end
        out=isequal(in,1) | isequal(in,0);

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end

    end
    function out = isInt(in,key)
        if ~isnumeric(in)
            out=0;
            return
        end
        out=~(mod(in,1));

        if ~exist('key','var') || isempty(key)
            return
        elseif strcmp(key,'all')
            out=all(out);
        else
            error(['Unhandled key: '  key ]);
        end

    end
    function out = isDouble(in)
        out=isa(in,'double');
    end
    function out = isSingle(in)
        out=isa(in,'single');
    end
    function types=typeSet()
        types={ ...
            'double'...
            ,'single'...
            ,'int8'...
            ,'int16'...
            ,'int32'...
            ,'int64'......
            ,'uint8'......
            ,'uint16'...
            ,'uint32'...
            ,'uint64'...
        };
    end
    function str=toStr(num,n,bBracket,bSpace,sciCrit)
        % n - sig dec digits
        if islogical(num)
            num=double(num);
        end
        if isempty(num)
            str='';
            return
        end
        if exist('n','var') && ~isempty(n) && n~=0
            n=min(max(Num.nSigDec(num),[],'all'),n);
            n={['%.' num2str(n) 'f ']};
        else
            n={};
        end
        if nargin < 3 || isempty(bBracket)
            bBracket=false;
        end
        if nargin < 4 || isempty(bSpace)
            bSpace=0;
        end
        if nargin < 5
            sciCrit=5;
        end


        if size(num,1) > 1
            s=arrayfun(@(x) tostrfun__(x,n,sciCrit), num,'UniformOutput',false);
            str=Cell.toStr(s,bSpace);
            if bBracket
                str=strrep(str,newline,['  ' newline '  ']);
                str=[ char(91) ' ' str ' ' char(93)];
            end
            return
        end

        s=tostrfun__(num,n,sciCrit);
        str=regexprep(s,' +',',');
        if exist('bSpace','var') && ~isempty(bSpace) && bSpace
            str=strrep(str,',',', ');
        end

        if exist('bBracket','var') && ~isempty(bBracket) && bBracket && numel(num) > 1
            str=['[ ' str ' ]'];
        end
        function out=tostrfun__(in,n,sciCrit)
            if isnan(in)
                out='NaN';
                return
            end

            if abs(Num.sciMag(in)) > sciCrit
                [float,exp]=Num.toSci(in);
                if float==0 && exp==0
                    out=num2str(0,n{:});
                else
                    float=num2str(float,n{:});
                    out=[float 'x10^' num2str(exp)];
                end
            else
                out=num2str(in,n{:});
            end

        end
    end


end
methods(Static, Access=private)
    % https://www.mathworks.com/matlabcentral/answers/142819-how-to-find-number-of-significant-figures-in-a-decimal-number
    function n=sigfun(x)
        if( x == 0 )
            n = 0;
            return;
        end
        x = abs(x);
        y = num2str(x,'%25.20e'); % Print out enough digits for any double
        z = [' ' y]; % Pad beginning to allow rounding spillover
        n = find(z=='e') - 1; % Find the exponent start
        e = n;
        while( str2double(y) == str2double(z) ) % While our number is still equal to our rounded number
            zlast = z;
            c = z(e); % Least significant printed digit
            if( c == '.' )
                e = e - 1;
                c = z(e);
            end
            z(e) = '0'; % 0 the least significant printed digit
            e = e - 1;
            if( c >= '5' ) % Round up if necessary
                c = z(e);
                if( c == '.' )
                    e = e - 1;
                    c = z(e);
                end
                while( true ) % The actual rounding loop
                    if( c == ' ' )
                        z(e) = '1';
                        break;
                    elseif( c < '9' )
                        z(e) = z(e) + 1;
                        break;
                    else
                        z(e) = '0';
                        e = e - 1;
                        c = z(e);
                        if( c == '.' )
                            e = e - 1;
                            c = z(e);
                        end
                    end
                end
            end
        end
        n = n - 1;
        z = zlast(1:n); % Get rid of exponent
        while( z(n) == '0' ) % Don't count trailing 0's
            n = n - 1;
        end
        n = n - 2; % Don't count initial blank and the decimal point.
    end
    function R = round(X,dec)
        % function R = Num.round(X,dec)
        %
        %   example call: Num.round([.22 .43 .65 1.13],.1)
        %
        % rounds input values to specified nearest decimal
        %
        % X:    input values
        % dec:  thing to round to
        %%%%%%%%%%%%%%%%%%
        % R:    rounded values

        R = round(X./dec).*dec;
    end
    function out=inc(cur,incr,mini,maxi)
        new=cur+incr;
        if new < mini
            out=mini;
        elseif new > maxi
            out=maxi;
        else
            out=new;
        end
    end
    function cur=incRot(cur,incr,mini,maxi)
        cur=cur+incr;

        if cur==maxi && incr > 0
            cur=mini;
        elseif cur==mini && incr < 0
            cur=maxi;
        elseif cur < mini
            cur=mini;
        elseif incr > maxi
            cur=maxi;
        end
    end
    function val=Rotate(val,vals)
        N=length(vals);
        ind=contains(vals,val);
        n=ind+1;
        if n > ind
            n=1;
        end
        val=vals{n};
    end

    function out=alphaU(in)
        out=alphaUpperV;
        out=out(in);
    end
    function out=ordinal(in)
        switch in
        case 1
            out='1st';
        case 2
            out='2nd';
        case 3
            out='3rd';
        otherwise
            out=[num2str(in) 'th'];
        end
    end
    function [txt] = literal(num)
        if all(ischar(num))
            num=str2double(num);
        end
        switch abs(num)
        case 1
            txt='one';
        case 2
            txt='two';
        case 3
            txt='three';
        case 4
            txt='four';
        case 5
            txt='five';
        case 6
            txt='six';
        case 7
            txt='seven';
        case 8
            txt='eight';
        case 9
            txt='nine';
        case 0
            txt='zero';
        case{Inf,19}
            txt='infinity';
        otherwise
            if Alph.is(num)
            disp('String contains non-number') %We will change this later
            end
        end
        if num<0
            txt=['negative-' txt];
        end
    end

    function str=fldStr(nums)
        if size(nums,1)==1
            nums=num2cell(transpose(nums));
        else
            nums=num2cell(nums);
        end
        str=cell(length(nums),1);
        for i = 1:length(nums)
            str{i}=strrep(num2str(nums{i}),'-','n');
            str{i}=strrep(str{i},'.','_');
            if ~contains(str{i},'n')
                str{i}=['p' str{i}];
            end
        end
        if iscell(str) && length(str)==1
            str=str{1};
        end
    end
    function out=bCombs(nplaces)
        n=bi2de(ones(1,nplaces));
        out=de2bi(0:n);
    end




end
end
