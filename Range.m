classdef Range < handle
methods(Static)
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
    function y = exp(x1,x2,n)
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

        y = exp(linspace(log(x1),log(x2),n));

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
