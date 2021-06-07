classdef Mat < handel
methods
    function [year, release, full] = version()
        % function [year, release, full] = Mat.version()
        % returns current matlab version
        %
        % example call:
        %    Mat.version
        %
        % Outputs:
        %    year    - matlab version year as number
        %    release - year iteration number (a=1, b=2 ...)
        %    full    - full version (eg. '2017a')

        verInfo = ver;
        full=verInfo(1).Release(3:end-1);
        year = str2num(verInfo(1).Release(3:end-2));
        release = verInfo(1).Release(end-1);
        switch release
            case 'a'
                release=1;
            case 'b'
                release=2;
            case 'c'
                release=3;
            case 'd'
                release=4;
        end
    end
end
