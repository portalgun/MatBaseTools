classdef Sec < handle
methods(Static)
    function [hr,min,sec,ms]=human(in)
        %if nargin < 1 || isempty(in)
        %    in=datetime('now','TimeZone','local');
        %end
        hr=floor(in/3600);
        in=in-3600*hr;
        min=floor(in/60);
        in=in-60*min;
        sec=floor(in);
        ms=round(100*(round(in-floor(in),2)));
    end
    function out=humanStr(in)
        [hr,min,sec,ms]=Time.Sec.human(in);
        out=[sprintf('%02u',hr) ':' sprintf('%02u',min) '.' sprintf('%02u',sec) '.' sprintf('%02u',ms)];
    end
    function out=unix(in)
        if nargin < 1 || isempty(in)
            in='now';
        end
        out=floor(posixtime(datetime(in,'TimeZone','local')));
    end
    function out=unixStr(in)
        if nargin < 1
            in=[];
        end
        out=sprintf('%.0f',Time.Sec.unix(in));
    end
end
end
