classdef Range < handle
methods(Static)
    function [ROWS,COLS]=getConvRC(IszRC,kernSz)
        Rh=floor(kernSz(1)/2);
        Rw=floor(kernSz(2)/2);
        COLS=Rw+1:IszRC(2)-Rw-1;
        ROWS=Rh+1:IszRC(1)-Rh-1;
    end
    function out=isMonotonicInc(X)
        if nargin < 2 || isempty(dim)
            if Vec.isRow(X)
                dim=2;
            else
                dim=1;
            end
        end
        inc=diff(X,[],dim);
        d=diff(inc,[],dim);
        out=(all(d > 0,dim) || all(abs(d) < 1e-10,dim))  && all(inc >= 0,dim);
    end
    function out=isMonotonicDec(X,dim)
        if nargin < 2 || isempty(dim)
            if Vec.isRow(X)
                dim=2;
            else
                dim=1;
            end
        end
        inc=diff(X,[],dim);
        d=diff(inc,[],dim);
        out=(all(d > 0,dim) | all(abs(d) < 1e-10,dim))  & all(inc <= 0,dim);
    end
    function out=isMonotonicIncStrict(X)
        if nargin < 2 || isempty(dim)
            if Vec.isRow(X)
                dim=2;
            else
                dim=1;
            end
        end
        inc=diff(X,[],dim);
        d=diff(inc,[],dim);
        out=(all(d > 0,dim) | all(abs(d) < 1e-10,dim))  & all(inc > 0,dim);
    end
    function out=isMonotonicDecStrict(X)
        if nargin < 2 || isempty(dim)
            if Vec.isRow(X)
                dim=2;
            else
                dim=1;
            end
        end
        inc=diff(X,[],dim);
        d=diff(inc,[],dim);
        out=(all(d > 0,dim) | all(abs(d) < 1e-10, dim))  & all(inc < 0,dim);
    end

    function out=isLog(X,dim)
        if nargin < 2 || isempty(dim)
            if Vec.isRow(X)
                dim=2;
            else
                dim=1;
            end
        end
        d=diff(X,3,dim);
        out=all(d > 0,dim) | all(d < 0,dim);
    end
    function out=log(i,j,n, a)
    %function out=lnspace(i,j,n=50,k=1)
    % independnt of log base use
        if ~exist('n','var') || isempty(n); n=50; end
        if ~exist('k','var') || isempty(k); k=1; end
        temp=exp(linspace(log(i)*a, log(j)*a,n));

        if a==1; out=temp; return; end;

        temp=(temp-min(temp));
        temp=temp/max(temp);
        out = temp*(j-i) + i;

    end
    function out=colonFun(fun,varargin)
        if nargin == 2
            s=1;
            m=[];
            e=varargin{1};
        elseif nargin == 3
            s=varargin{1};
            m=[];
            e=varargin{2};
        elseif nargin == 4
            s=varargin{1};
            m=varargin{2};
            e=varargin{3};
        end
        ss=fun(s);
        ee=fun(e);

        % TODO
    end
    function out=colonExp(varargin)
        if nargin == 1
            s=1;
            m=[];
            e=varargin{1};
            a=[];
        elseif nargin == 2
            s=varargin{1};
            m=[];
            e=varargin{2};
            a=[];
        elseif nargin == 3
            s=varargin{1};
            m=[];
            e=varargin{2};
            a=varargin{3};
        elseif nargin == 4
            s=varargin{1};
            m=varargin{2};
            e=varargin{3};
            a=varargin{4};
        end

        if isempty(a)
            if isempty(m)
                r=log(s):log(e);
            else
                %M=Num.logn(m,a);
                M=m;
                r=log(s):M:log(e);
            end
            out=exp(r);
        else
            if isempty(m)
                r=Num.logn(s,a):Num.logn(e,a);
            else
                %M=Num.logn(m,a);
                M=m;
                r=Num.logn(s,a):M:Num.logn(e,a);
            end
            out=a.^r;
        end
    end
    function y = exp(x1,x2,n,a)
        % function y = Range.exp(x1,x2,n)
        %
        %   generates vector of n expontially spaced points between x1 and x2
        %
        % x1: limit 1
        % x2: limit 2
        % n:  number of points (default 10)
        % %%%%%%%%%%%%%%%%%%%%%%
        % y:  exponentially spaced points (linear on a log axis)

        if nargin == 2, n = 10; end
        if nargin < 4, a = []; end

        if isempty(a)
            y = exp(linspace(log(x1),log(x2),n));
        else
            y=a.^(linspace(Num.logn(x1,a),Num.logn(x2,a),n));
        end

    end

    function rng = str(num)
        %function rng = Range.str(num)
        %Takes a vector of numbers and creates a short string
        % example call:
        %   Range.str([1 2 3 5 6 8 12])
        num=unique(sort(num));
        if numel(num)==1
            rng=num2str(num);
            return
        end
        rng='';
        first=num(1);
        for i = 2:length(num)
            cur=num(i);
            curM=num(i-1);

            if cur~=curM+1
                if i == length(num)
                    if curM==first
                        rng=[rng num2str(first)];
                    else
                        rng=[rng num2str(first) '-' num2str(curM)];
                    end
                else
                    if curM==first
                        rng=[rng num2str(first) ','];
                    else
                        rng=[rng num2str(first) '-' num2str(curM) ','];
                    end
                end
                first=cur;
            elseif i == length(num)
                rng=[rng num2str(first) '-' num2str(cur)];
            end
        end
    end
end
end
