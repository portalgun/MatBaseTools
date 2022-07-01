classdef Sys < handle
methods(Static)
    function term(cmd)
        term=getenv('TERM');

        pre=['export DISPLAY=:0; ' ...
             'xhost local:$(whoami) > /dev/null; '  ...
             'export LD_PRELOAD=/usr/lib/libstdc++.so; ' ...
             'export LD_LIBRARY_PATH=/usr/lib/xorg/modules; ' ...
            ];
        CMD=sprintf('%s %s -e ''%s''',pre,term,cmd);
        unix(CMD);
    end
    function [out,bSuccess] = run(cmd,bSpace)

        % function [out,bSuccess] = Sys.run(cmd,bSpace)
        %
        %   example call: Sys.run('ls',1)
        %
        % makes 'system' command more usable
        %
        % cmd:      string specifying standard bash command
        % bSpace:   use if output is sperated by spaces rather than lines
        %           for example - using 'ls' instead of 'ls -l'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % out:      output from standard bash command formatted as a cell
        % bSuccess: boolean indicating whether command was successfull
        %           1 -> success
        %           0 -> failure

        % CREATED BY DAVID WHITE
        if ~exist('bSpace','var')  || isempty(bSpace)
            bSpace=0;
        end

        %RUN TRADITIONAL SYSTEM COMMAND
        if isunix
            [bSuccess,out]=unix(cmd);
        else
            [bSuccess,out]=system(cmd);
        end
        %MAKE STATUS CONSISTENT WITH MATLAB
        bSuccess=~bSuccess;

        %SPLIT INTO CELLS BY SPACES OR NEWLINES
        if bSpace
            try
                out=split(out);
            catch
                out=Split(out);
            end
        else
            try
                out=split(out,newline);
            catch
                out=Split(out,char(10));
            end
        end
        %REMOVE EMPTY LINES
        out=out(~cellfun('isempty',out));
    end
    function [status,out]=command(cmd)
        if isunix()
            if Sys.islinux()
                ld='export LD_LIBRARY_PATH=""; ';
            else
                ld='';
            end
            [status,msg]=unix([ld cmd]);
        else
            [status,msg]=system(cmd);
        end
        out=msg(1:end-1);
    end
    function out=users()
        out=Sys.usersCmd_();
    end
    function out=isInstalled(cmd)
        % XXX
        try
            out=Sys.isInstalledC_(cmd);
        catch
            out=Sys.isInstalledCmd_(cmd);
        end
    end
    function [out,bSuccess]=which(cmd)
        %out=Sys.whichC_(cmd); % XXX DOESN"T WORK ON SOME MACHINES?
        out=Sys.whichCmd_(cmd);
        %
        if isempty(out) || isequal(out,false)
            out=[];
            bSuccess=false;
        else
            bSuccess=true;
        end
    end
    function out = whoami()
        % XXX
        if ispc()
            out=Sys.whoamiCmd_();
        else
            try
                out=Sys.whoamiC_();
            catch
                out=Sys.whoamiCmd_();
            end
        end
    end
    function out = groups()
        % XXX
        out=Sys.groupsCmd_();
    end
    function h = hostname()
        % XXX
        if ispc() % XXX
            h=Sys.hostnameCmd_();
        else
            try
                h=Sys.hostnameC_();
            catch
                h=Sys.hostnameCmd_();
            end
        end
        %h=Sys.hostnameCmd_();
    end
    function out = islinux()
        switch computer
        case {'GLNXA64','GLNXA32'}
            out=1;
        otherwise
            out=0;
        end
    end
    function out=isWnMngr()
        out=isWnMngrCmd_();
    end
    function out=os()
        if ismac()
            out='mac';
        elseif ispc
            out='win';
        elseif Sys.islinux
            out='linux';
        elseif isunix
            out='unix';
        end
    end
end
methods(Static, Access=private)
    function out = whoamiC_()
        out=whoami_cpp();
    end
    function out = whoamiCmd_()
        % function out = Sys.whoami()
        % Simply returns system username
        [out]=Sys.run('whoami');
        out=out{1};
    end
    function out=usersCmd_()
        if Sys.islinux
            cmd='cat /etc/passwd | awk -F: ''{print $1}''';
            out=Sys.run(cmd);
        elseif ispc
            ignore={'The command completed successfully.','User accounts for','------'};
            cmd='net user';
            out=Sys.run(cmd);

            ind=~contains(out,ignore);
            out=out(ind);
            out=cellfun(@(x) transpose(strsplit(x)), out,'UniformOutput',false);
            out=vertcat(out{:});
            out=out(~cellfun('isempty',out));

        end
    end
    function out = groupsCmd_()
        % function out = groups()
        % Simply returns system groups user belongs to
        if isunix
            [out]=Sys.run('groups');
            out=out{1};
            out=transpose(strsplit(out));
        elseif ispc
            [out]=Sys.run('net localgroup');
            ind=startsWith(out,'*');
            out=out(ind);
            out=cellfun(@(x) x(2:end),out,'UniformOutput',false);
        end
    end
    function out=isInstalledC_(cmd)
        out=isinstalled_cpp(cmd);
    end
    function out=isInstalledCmd_(cmd)
        out=Sys.whichCmd_(cmd);
        if isempty(out)
            out=false;
        else
            out=true;
        end
    end
    function out=whichC_(cmd)
        out=which_cpp(cmd);
    end
    function out=whichCmd_(cmd)
        [out,bSuccess]=Sys.run(['which ' cmd]);
        if ~bSuccess
            out=[];
        else
            out=out{1};
        end
    end
    function h = hostnameCmd_()

        % function localHostName = psyLocalHostName()
        %
        %   example call: localHostName = psyLocalHostName()
        %
        % returns the computer's local host name
        % %%%%%%%%%%%%%%%%%%%%%%%
        % localHostName:  duh!

        if Sys.islinux || ispc
            h = Sys.run('hostname');
            h=h{1};
        elseif ismac
            h = Sys.run('hostname -s');
            h=h{1};
        end
        h=strrep(h,'-','_');
    end
    function out=hostnameC_()
        out=hostname_cpp();
    end
    function [out]=isWnMngrCmd_()
        %CHECKs if a window manager is running, opposed to running the operating system in headless
        c=computer;
        if strcmp(c,'GLNXA64')
            cmd='ps -aux | grep -v "grep" | grep -c "Xorg"';
            [~,out]=system(cmd);
            out=strsplit(out);
            out=str2double(out(1));
        else
            out=1;
        end
    end
end
end
