classdef RE < handle
methods(Static)
    function out=ismatch(cell,exp,bIgnoreCase)
        %function out = Str.RE.ismatch(cell,exp,bIgnoreCase)
        %version of regexp that works will cells, returning a logical index
        if ~exist('bIgnoreCase','var') || isempty(bIgnoreCase)
            bIgnoreCase=0;
        end
        if ~iscell(cell) && bIgnoreCase==1
            out=~isempty(regexp(cell,exp,'ignorecase'));
        elseif ~iscell(cell)
            out=~isempty(regexp(cell,exp,'ignorecase'));
        elseif bIgnoreCase==1
            out=~cell2mat(cellfun( @(x) isempty(regexp(x,exp,'ignorecase')),cell,'UniformOutput',false)');
        else
            out=~cell2mat(cellfun( @(x) isempty(regexp(x,exp)),cell,'UniformOutput',false)');
        end
    end
    function re=combine(res)
        if ismac()
            re=['(' strjoin(res,'|') ')'];
        else
            re=['(' strjoin(res,'|') ')'];
        end
    end
    function out=match(str,re,bIgnoreCase)
        if ~exist('bIngoreCase','var') || isempty(bIgnoreCase)
            bIgnoreCase=0;
        end
        [s,e]=regexp(str,re);
        % XXX handle multiple
        out=str(s:e);
    end
    function out=rep(in,re,rep,varargin)
        out=regexprep(in,re,rep,varargin{:});
    end
end
end
