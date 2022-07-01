classdef Git < handle
methods(Static)
    function version = parse_version(version)
    end
    function direName=get_version_dire_name(version,site)
        %site__prj__versionORhash
        site=regexprep(site,'https*://?','');
        site=regexprep(site,'\..*?/','/');
        if endsWith(site,'/')
            site=site(1:end-1);
        end
        direName=strrep(site,'/','__');
        if ~isempty('version')
            direName=[direName '@' version];
        end
    end
    function [msg,status]=checkout(dire,version)
        %checkout -> into lib
        %dire stable -> lib
        %dire=Dir.parent(dire);
        oldDir=cd(dire);
        cl=onCleanup(@() cd(oldDir));
        cmd=['git checkout ' version ' --quiet'];
        [status,msg]=Sys.command(cmd);
        if status==0
            msg='';
        end
    end
    function [MSG,exitflag]=clone(site,direName,local_state)
        msg=[];
        if nargout >= 3 && ~isempty(local_state)
            out=local_state;
        else
            out=Git.local_state(direName);
        end
        % 0 dire doesn't exist            - Gd
        % 1 empty                         - Gd but rm
        % 2 not empty with files, no .git - Bd
        % 3 has git                       - Gd no clone
        % 4 has git, origin doesn't match - Bd

        if out==1
            rmdir(direName);
        end

        if isempty(msg)
            out=0;
            cmd=['git clone -q ' site ' ' direName ];
            [exitflag,msg]=Sys.command(cmd);

            if exitflag~=0
                out=1;
                msg=['Git error:' newline msg(1:end-1)];
            end

        end

        if nargout < 1
            Error.warnSoft(msg);
        else
            MSG=msg;
        end

    end
    function hash=git_hash(dire)
        if exist('dire','var') && ~isempty(dire)
            oldDir=cd(dire);
            bRestore=1;
        else
            bRestore=0;
        end
        if isunix
            [~,hash]=unix('git rev-parse HEAD');
            hash=strsplit(hash,newline);
            hash(cellfun(@isempty,hash))=[];
            hash=branch{1};
        else
            [~,hash]=system('git rev-parse HEAD');
        end
        if bRestore
            cd(oldDir);
        end
    end
    function branch=get_branch(dire)
        if exist('dire','var') && ~isempty(dire)
            oldDir=cd(dire);
            bRestore=1;
        else
            bRestore=0;
        end
        if isunix
            [~,branch]=unix('git rev-parse --abbrev-ref HEAD');
            branch=strsplit(branch,newline);
            branch(cellfun(@isempty,branch))=[];
            branch=branch{1};
        else
            [~,branch]=system('git rev-parse --abbrev-ref HEAD');
        end
        if bRestore
            cd(oldDir);
        end
    end
    function origin=get_origin(dire)
        if exist('dire','var') && ~isempty(dire)
            oldDir=cd(dire);
            bRestore=1;
        else
            bRestore=0;
        end
        if isunix
            [~,origin]=unix('git config --get remote.origin.url');
            origin=strsplit(origin,newline);
            origin(cellfun(@isempty,origin))=[];
            origin=origin{1};
        else
            system('git config --get remote.origin.url');
        end
        if bRestore
            cd(oldDir);
        end
    end
    function [stats,ms]=update(direName)
        % REFS
        if nargin > 0 && ~isempty(direName)
            oldDir=cd(direName);
            cl=onCleanup(@() cd(oldDir));
        end
        cmd=sprintf('git remote update');
        [status,ms]=Sys.command(cmd);
    end
    function out=needsPull(direName)
        if nargin > 0 && ~isempty(direName)
            oldDir=cd(direName);
            cl=onCleanup(@() cd(oldDir));
        end

        cmd=sprintf('git status -uno');
        [status,ms]=Sys.command(cmd);
        out=~isempty(ms);
    end
    function [status,msg]=pull(direName,branch)
        if nargin > 0 && ~isempty(direName)
            oldDir=cd(direName);
            cl=onCleanup(@() cd(oldDir));
        end
        if nargin < 2 || isempty(branch)
            branch='';
        end
        cmd=sprintf('git pull origin %s',branch);
        [status,msg]=Sys.command(cmd);
    end
    function [exitflag,state,msg]=local_state(direName,site)
        % 0 dire doesn't exist            - Gd
        % 1 empty                         - Gd but rm
        % 2 not empty with files, no .git - Bd
        % 3 has git                       - Gd no clone
        %
        % 4 has git, origin doesn't match - Bd
        % 5 url is unreachable            - Bd
        % 6 timeout
        % 7 needs pull

        msg=[];
        exitflag=0;
        bExist=Dir.exist(direName);
        bGitExist=Dir.exist([direName '.git']);
        if ~bExist
            state=0;
        elseif  ~bGitExist && length(dir(direName)) == 2
            state=1;
        elseif ~bGitExist && length(dir(direName)) > 2
            exitflag=1;
            state=2;
            msg=['Destination directory not empty and not detected as repo ' direName];
        else
            state=3;
        end

        if (nargin < 2 || isempty(site)) || ~isempty(msg);
            return
        end

        if state == 3
            origin=Git.get_origin(direName);
            if ~strcmp(origin,site)
                exitflag=1;
                state=4;
                msg=['Origin does not match site ' site];
            end
            return
        end

        % CHECK SITE
        cmd=sprintf('timeout 6 git ls-remote "%s.git" CHECK_GIT_REMOTE_URL_REACHABILITY',site);
        [status,ms]=Sys.command(cmd);
        if status>1 % XXX correct?
            exitflag=1;
            state=6;
            msg=['Check site url. Timeout while reaching site ' site];
            return
        elseif status==1
            exitflag=1;
            state=5;
            msg=ms;
            return
        end

    end
end
end
