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
    function out=match(c,exp,bIgnoreCase)
        if ~exist('bIngoreCase','var') || isempty(bIgnoreCase)
            bIgnoreCase=0;
        end
        out=Str.RE.ismatch(c,exp,bIgnoreCase);
        out=c(out);
    end
    function out=rep(in,re,rep,varargin)
        out=regexprep(in,re,rep,varargin{:});
    end
end
end
