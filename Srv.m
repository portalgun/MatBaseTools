classdef Srv < handle
properties
end
methods
    function out=is(in)
    end
    function out=get()
    end
    function out=readCfg()
        RdCfg.
    end
    function code = isMounted(bSrv,bNoRoot)
    %IF A SERVER DIRECTORY, CHECK TO SEE IF REMOTE DIRECTORY IS MOUNTED
        code='';

        if bSrv
            exitflag=chkSrvMnt();
            if exitflag
                code='s';
            end
        elseif bNoRoot
            code='m';
            exitflag=1;
        end
    end
    function []=print_opt(code,bSrv,drive)
        if ismember('m',code) && ispc
            disp(['Drive ' drive ' is not mounted or accessible']);
            return
        elseif ismember('m',code) && isunix
            disp('Root directory is not accessible')
            return
        end
        if bSrv && ~ismember('s',code)
            disp('Server is mounted')
        end
        if ~ismember('e',code)
            disp('All directories exist.')
        end
        if isempty(code)
            disp('Permissions look good.')
        end
    end
end
end
end
