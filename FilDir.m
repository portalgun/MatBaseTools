classdef FilDir < handle
properties(Constant)
    bC=1
end
methods(Static)
%% EXIST
    function out=exist(thing)
        out=(exist(thing,'file')==2 || exist(thing,'file')==7);
    end
    function out=abs(thing)
        if isunix && ~startsWith(thing,'/')
            out=[pwd filesep thing];
        elseif ispc && ~Str.RE.ismatch(thing,'[A-Z]:\')
            out=[pwd fielsep thing];
        else
            out=thing;
        end
    end
    function out=isequal(dire1,dire2);
        if isunix()
            dire1=Dir.resolve(dire1);
            dire2=Dir.resolve(dire2);
            out=isequal(dire1,dire2);
        end
    end
    function out=resolve(dire)

        if (isunix && ~startsWith(dire,filesep)) || (ispc && ~Str.RE.ismatch(dire,'^[A-Z]:.*'));
            dire=[pwd filesep dire];
        end

        old=pwd;
        cl=onCleanup(@() builtin('cd',old));
        dire=Dir.highest(dire);
        builtin('cd',dire);
        if isunix()
            [out,bSuccess]=Sys.run(['pwd -P']);
        else
            [out,bSuccess]=Sys.run(['echo %cd%']);
        end
        if ~bSuccess
            error(out);
        end
        out=out{1};
    end
%% FIND
    function out= find(dire,re,depth,ftype)
        if ~exist('depth','var')
            depth=[];
        end
        if ~exist('ftype','var')
            ftype=[];
        end
        if isunix()
            out=FilDir.findUnix_(dire,re,depth,ftype);
        elseif ispc()
            out=FilDir.findPC_(dire,re,depth,ftype);
        else
            error('unhandled os');
        end
    end
    function out=check(thing)
        Dir.highest(thing);
    end
%% PERMS
    function [rPerm,wPerm,xPerm]=perms(file,bQuiet)
    % function [rPerm,wPerm,xPerm]=chkPerms(file)
    % Checks permissions of a file
        if ~exist('bQuiet','var') || isempty(bQuiet)
            bQuiet=0;
        end
        if ~exist('file','var') || isempty(file)
            error('chkPerms requires filename');
        elseif bQuiet & ~exist('file','var') || isempty(file)
            Error.warnSoft(['chkPerms: file ' file ' does not exist!']);
        end

        %%
        user=Sys.whoami();
        Groups=Sys.groups();
        permissions=FilDir.prms_(file);
        owners=Fil.owns(file);
        if isunix
            [rPerm,wPerm,xPerm]=FilDir.unix_fun_(user,Groups,owners,permissions);
        elseif ispc
            [rPerm,wPerm,xPerm]=FilDir.pc_fun_(user,Groups,owners,permissions);
        end
        rPerm=logical(rPerm);
        wPerm=logical(wPerm);
        xPerm=logical(xPerm);
    end
%% LINK
    function easyln(src,dest,bTest,home,bWarn)

        if nargin < 3 || isempty(bTest)
            bTest=false;
        end

        if nargin < 4 || isempty(home)
            home=Dir.home();
        end
        if nargin < 5 || isempty(bWarn)
            bWarn=true;
        end
        if endsWith(home,'/')
            home=home(1:end-1);
        end
        src=strrep(src,'~',home);

        % get source of source
        if ~ispc
            src=FilDir.readLink(src);
        end


        % LINK IF DOESNT EXIST
        bExist=exist(dest,'dir') || exist(dest,'file');
        if ~bExist
            FilDir.ln(src,dest);
            return
        end


        % ERROR IF DEST NOT SYMBOLIC
        bLink=FilDir.isLink(dest);
        if ~bLink
            error([ 'Unexpected non-symbolic link at ' dest ]);
            return
        end

        % CHECK FIX IF EXISTING IS POINTING TO INCORRECT LOCATION
        trueSrc=FilDir.readLink(dest);
        if isnan(src)
            error('Something went wrong');
        end
        if ~bTest && ~strcmp(src,trueSrc)
            if bWarn
                Error.warnSoft(['Fixing bad symlink ' trueSrc ' to ' src]);
            end
            delete(dest);
            FilDir.ln(src,dest);
        elseif bTest
            disp(dire);
            disp(src);
            disp(src);
        end
    end

    function bSuccess=ln(origin,destination)
        if FilDir.check_cell_src_dest(origin,destination)
            for i = 1:length(origin)
                FilDir.ln(origin{i},destination{i});
            end
        elseif FilDir.bC && isunix() %
            bSuccess=FilDir.ln_C_unix_(origin,destination);
            %bSuccess=FilDir.lnUnix_(origin,destination);
        elseif isunix
            bSuccess=FilDir.lnUnix_(origin,destination);
        elseif FilDir.bC && ispc() %
            try
                bSuccess=FilDir.ln_C_win32_(origin,destination);
            catch
                bSuccess=FilDir.ln_win32_(origin,destination);
            end
        elseif ispc()
            bSuccess=FilDir.ln_win32_(origin,destination);
        else
                error('unhandled OS');
        end
    end
    function bSuccess=link(origin,destination)
        bSuccess=FilDir.ln(origin,destination);
    end
    function bSuccess=relink(origin,destination);
        FilDir.unlink(destination);
        FilDir.ln(destination);
    end
    function unlink(thing)
        if iscell(thing)
            cellfun(@FilDir.unlink,thing);
            return
        end
        if ~FilDir.isLink(thing)
            error(['File/directory ' thing ' is not a link.']);
        else
            % TESTED
            delete(thing);
        end
    end
    function bSuccess=isLink(thing)
        if FilDir.bC && isunix()
            bSuccess=FilDir.isLink_C_unix_(thing);
        elseif isunix()
            bSuccess=FilDir.isLink_unix_(thing);
        elseif FilDir.bC && ispc()
            try
                bSuccess=FilDir.isLink_C_win32_(thing);
            catch
                bSuccess=FilDir.isLink_win32_(thing);
            end
        elseif ispc()
            bSuccess=FilDir.isLink_win32_(thing);
        end
        if isempty(bSuccess)
            bSucces=false;
        end
    end
    function out=readLink(thing)
        if FilDir.bC && isunix()
            out=FilDir.readLink_C_unix(thing);
        elseif isunix()
            out=FilDir.readLink_unix_(thing);
        elseif FilDir.bC && ispc()
            try
                out=FilDir.readLink_C_win32_(thing);
            catch
                out=FilDir.readLink_win32_(thing);
            end
        elseif ispc()
            out=FilDir.readLink_win32_(thing);
        end
    end

%% BACKUP
    function mkbk(file,bDire)
        if nargin > 2 || isempty(bDire) || ~bDire
            bkDir='';
        else
            bkDir=['BACKUP' filesep];
        end
        if Dir.exist(file)
            file=Dir.parse(file);
            dire=Dir.parent(file);
            name=Dir.last(file);
            name=name(1:end-1);

            re=[name '__[0-9]{3}'];
            frmt=[dire bkDir name '__' '%03d'];
            ext='';
            matches=Dir.reDirs(dire,re);
        elseif Fil.exist(file)
            [dire,name,ext]=Fil.parts(file);
            re=[name '__[0-9]{3}' '\' ext];
            frmt=[dire bkDir name '__' '%03d' ext];
            matches=Dir.reFiles(dire,re);
        else
            error(['file/directory ' file ' does not exist.']);
        end
        if isempty(matches)
            num=0;
        else
            num=max( cellfun(@str2double, ...
                                        strrep( ...
                                        strrep(matches, ext, ''), ...
                                        [name '__'],''))) + 1;
        end
        newname=sprintf(frmt,num);
        if ~isempty(bkDir)
            Dir.mk([dire bkDir]);
        end
        FilDir.cp(file,newname);

    end
    function cp(src,dest,bLn)
        % XXX doesn't work well with symlinks
        if FilDir.check_cell_src_dest(src,dest)
            for i = 1:length(src)
                FilDir.cp(src{i},dest{i});
            end
        else
            [stat,ms]=copyfile(src,dest);
        end
        if nargin < 0
            status=sta;
            if nargin < 1
                msg=ms;
            end
        end
    end
    function [status,msg]=mv(src,dest)
        if FilDir.check_cell_src_dest(src,dest)
            for i = 1:length(src)
                FilDir.mv(src{i},dest{i});
            end
        else
            [stat,ms]=movefile(src,dest);
        end


        if nargin < 0
            status=stat;
            if nargin < 1
                msg=ms;scl . append /Groups/admin GroupMembership
            end
        end
    end

end
methods(Static, Access=private)
%%% LINK
%% LN
    function out=ln_C_unix_(origin,destination)
        try
            out=ln_unix_cpp(origin,destination);
        catch ME
            out=ln_cpp(origin,destination);
        end
        out=FilDir.isLink(destination);
    end
    function out=ln_C_win32_(origin,destination)
        out=ln_win32_cpp(origin,destination);
    end
    function bSuccess=lnUnix_(origin,destination)
        %ln(origin,destination)
        %create symbolic links
        cmd=['ln -s ' origin ' ' destination];
        [msg,bSuccess]=Sys.run(cmd);
    end
    function bSuccess=ln_win32_(origin,destination)
        flag='';
        if Dir.exist(origin)
            flag=['/d '];
        end
        cmd=['mklink ' flag destination ' ' origin];
        [~,bSuccess]=Sys.run(cmd);
    end
%% ISLINK
    function out=isLink_C_unix_(thing)
        try
            out=issymlink_cpp(thing);
        catch
            out=issymlink_unix_cpp(thing);
        end
    end
    function out=isLink_C_win32_(thing)
        out=issymlink_win32_cpp(thing);
    end
    function out= isLink_unix_(dire)
        out=~unix(['test -L ' dire]);
    end
    function out=isLink_win32_(thing)
        %cmd=sprintf('dir %s | find "<SYMLINK>" >NUL; if errorlevel 1 echo true else echo false',thing); %
        %cmd=sprintf(' for %i in ("%DIR%") do set attribs=%~ai
        cmd=sprintf('fsutil reparsepoint query "%s" | find "Symbolic Link" >nul && echo true || echo false',thing);%
        [~,out]=system(cmd);
        spl=strsplit(out,'\n');
        spl(cellfun(@isempty,spl))=[];
        res=strtrim(spl{1});
        if strcmp(res,'true')
            out=true;
        elseif strcmp(res,'false');
            out=false;
        else
            error(['unexpected result: ''' res '''']);
        end
    end
    %function out= isLink_pc_(dire)
    %    cmd=['powershell -Command "((get-item ' dire ' -Force -ea SilentlyContinue).Attributes.ToString())"'];
    %    [~,out]=system(cmd);
    %    out=strrep(out,newline,'');
    %    out=contains(out,'ReparsePoint');
    %end
%% READLINK
    function out=readLink_C_unix(thing)
        try
            out=readlink_cpp(thing);
        catch
            out=readlink_unix_cpp(thing);
        end
    end
    function out=readLink_C_win32(thing)
        out=readlink_win32_cpp(thing);
    end
    function out =readLink_win32_(dire)
        cmd=['powershell -Command "(Get-Item ' dire ').Target'];
        [~,src]=system(cmd);
        out=strrep(src,newline,'');
        return
    end
    function out =readLink_unix_(dire)
        if ismac
            str=['readlink ' dire];
        elseif Sys.islinux
            out=readlink(dire);
            return
        end
        [bS,out]=unix(str);
        out=out(1:end-1);
        if (Sys.islinux && bS==1) || (ismac && bS==1 && ~isempty(out))
            out=nan;
        elseif ismac && (ismac && bS==1 && isempty(out))
            out=dire;
        end
    end

    function out = islinkbroken(dire)
        % TODO merge with readlink
        if isunix
            cmd=['[[ ! -e ' dire ' ]] && echo 1'];
            out=~unix(cmd);
        elseif ispc
            cmd=['DIR \a ' dire];
            [bSuccess,out]=system(cmd);
        end
    end
%% FIND

    function out=findPC_(dire,re,depth,ftype);
        if ~exist('depth','var') || isempty(depth)
            depthStr='';
        else
            depthStr=[' -Depth ' num2str(depth)];
        end
        if ~exist('ftype','var') || isempty(ftype)
            typeStr='';
        else
            if ftype=='f'
                typeStr=[' -File' ];
            else ftype=='d'
                typeStr=[' -Directory'];
            end
        end
                                %re
        pathStr=[' -Path "' dire '\"'];
        %nameStr=[' -Name \"' re '\"'];
        %cmd=['powershell -Command "Get-ChildItem' pathStr ' -Recurse' typeStr depthStr ' | Where-Object{ $_.FullName -match ''' re '''}| Select-Object -Property FullName'];

        cmd=['powershell -Command "(Get-ChildItem' pathStr ' -Recurse' typeStr depthStr ' | Where-Object{ $_.FullName -match ''' re '''}).FullName"'];
        [~,out]=system(cmd);
        if ~isempty(out)
            out=transpose(strsplit(out(1:end-1),newline));
        end
    end
    function out=findUnix_(dire,re,depth,ftype);
        if ~exist('dire','var') || isempty(dire)
            dire=pwd;
        end

        %try
            bFd=Sys.isInstalled('fd');
        %catch
            %bFd=false;
        %end
        if exist('depth','var') && ~isempty(depth) && bFd
            depthStr=['--maxdepth ' num2str(depth) ' '];
        elseif exist('depth','var') && ~isempty(depth)
            depthStr=['-maxdepth ' num2str(depth) ' '];
        else
            depthStr='';
        end
        if ~exist('ftype','var') || isempty(ftype)
            typeStr='';
        elseif ismember(ftype,{'f','d'}) && bFd
            typeStr=['--type ' ftype ' '];
        elseif ismember(ftype,{'f','d'})
            typeStr=['-type ' ftype ' '];
        elseif ~ismember(ftype,{'f','d'})
            error('Invalid type. Must be "f" or "d"');
        end
        if dire(end) ~= filesep
            dire=[dire filesep];
        end
        if bFd
            cmd=['fd -L -H --color never ' depthStr typeStr  '--regex ''' re  ''' --base-directory ' dire];
            [~,out]=unix(cmd);
        elseif ismac
            dired=dire;
            while endsWith(dired,filesep)
                dired=dired(1:end-1);
            end
            cmd=['find -L -E ' dired ' ' depthStr typeStr '-regex ''.*/' re '''' ];
            [~,out]=unix(cmd);

            out=strrep(out,dire,'');
            if isempty(out)
                cmd=['find -L ' dired ' ' depthStr typeStr '-regex ''.*/' re '''' ];
                [~,out]=unix(cmd);
                out=strrep(out,dire,'');
            end
        else
            %cmd=['find ' dire '  -regextype egrep ' depthStr typeStr '-regex ".*' filesep re '" -printf "%P\n" | cut -f 1 -d "."' ];
            cmd=['find ' dire '  -regextype egrep ' depthStr typeStr '-regex ''' re '''' ];
            [~,out]=unix(cmd);
            out=strrep(out,dire,'');
        end
        if ~isempty(out);
            out(end)=[];
            out=strsplit(out,newline);
        end
        out=transpose(out);
    end
    function [rPerm,wPerm,xPerm]=pc_fun_(user,Groups,owners,permissions)

        if ismember('\Everyone',owners)
            primary=1;
            secondary=1;
        end
        % TODO MANY THINGS

        rPerm=FilDir.parse_read_unix_(primary,secondary,permissions);
        wPerm=FilDir.parse_write_unix_(primary,secondary,permissions);
        xPerm=FilDir.parse_exec_unix_(primary,secondary,permissions);
    end
    function [rPerm,wPerm,xPerm]=unix_fun_(user,Groups,owners,permissions)
        %CHECK FOR PRIMARY OWNERSHIP
        primary=0;
        if strcmp(user,owners{1})
            primary=1;
        end

        %CHECK FOR GROUP OWNERSHIP
        secondary=0;
        if ismember(owners{2},Groups)
            secondary=1;
        end


        rPerm=FilDir.parse_read_unix_(primary,secondary,permissions);
        wPerm=FilDir.parse_write_unix_(primary,secondary,permissions);
        xPerm=FilDir.parse_exec_unix_(primary,secondary,permissions);
    end
    function rPerm=parse_read_unix_(primary,secondary,permissions)
        %CHECK FOR READ PERMISSION
        rPerm=0;
        if primary==1
            switch permissions(1)
            case {'4','5','6','7'}
            rPerm=1;
            end
        end

        if secondary==1
            switch permissions(2)
            case {'4','5','6','7'}
            rPerm=1;
            end
        end
        switch permissions(3)
        case {'4','5','6','7'}
            rPerm=1;
        end
    end

    function wPerm=parse_write_unix_(primary,secondary,permissions)
        %CHECK FOR Write PERMISSION
        wPerm=0;
        if primary==1
            switch permissions(1)
            case {'2','3','6','7'}
            wPerm=1;
            end
        end

        if secondary==1
            switch permissions(2)
            case {'2','3','6','7'}
            wPerm=1;
            end
        end
        switch permissions(3)
        case {'2','3','6','7'}
            wPerm=1;
        end
    end

    function xPerm=parse_exec_unix_(primary,secondary,permissions)
        %CHECK FOR EXECUTE PERMISSION
        xPerm=0;
        if primary==1
            switch permissions(1)
            case {'1','3','5','7'}
            xPerm=1;
            end
        end

        if secondary==1
            switch permissions(2)
            case {'1','3','5','7'}
            xPerm=1;
            end
        end

        switch permissions(3)
        case {'1','3','5','7'}
            xPerm=1;
        end
    end
%% PRINT
    function str=chkAllPrint(code,fulldir,highestdir,fname)
    %function []=chkAllPrint(code,fulldir,highestdir,fname)
        if ~exist('highestdir','var')
            highestdir=[];
        end
        if ~exist('fulldir','var')
            fulldir=[];
        end
        if ~exist('fname','var')
            fname=[];
        end

        str=str_fun(code,fulldir,highestdir,fname);
        if endsWith(str,newline)
            str=str(1:end);
        end
        if nargout < 1
            disp(str);
        end
    end
    function num=code2num(code)
        %% STATUS
        %% -1 empty name
        %% 0  file doesn't exist
        %% 1  file exists
        %% 2  direcotory doesnt exist
        %% 3  read but not write
        if isempty(code)
            status=0;
            return
        end


        bexit=0;
        num=0000;
        if ismember('E',code) % doesnt exit
            num=num+1000;
            bexit=1;
        end
        if ismember('e',code)
            num=num+100;
            bexit=1;
        end
        if ismember('_',code)
            num=num+2000;
            bexit=1;
        end
        if ismember('-',code)
            num=num+200;
            bexit=1;
        end
        if bexit==1
            return
        end
        num=num+77;
        if ismember('r',code)
            num=num-4;
        end
        if ismember('R',code)
            num=num-40;
        end
        if ismember('w',code)
            num=num-2;
        end
        if ismember('W',code)
            num=num-20;
        end
        if ismember('X',code)
            num=cnum-10;
        end
        if ismember('x',code)
            num=num-1;
        end
    end
    function permissions =prms_(file)
    % function permissions =perms(file)
    % returns unix permissions in number format
    %
    % NOTE TO WINDOWS USERS: 555 means read-only, otherwise all permissions granted (as long as ownership checks out)
    % CREATED BY DAVID WHITE
    if ismac
        cmd=['stat -f "%Lp" "' file '" | awk ''{print $1}'''];
    elseif Sys.islinux
        cmd=['stat -c "%a %n" "' file '" | awk ''{print $1}'''];
    elseif ispc
        permissions=FilDir.prms_pc_fun_(file);
        return
    end
    [permissions]=Sys.run(cmd);
    if iscell(permissions) && numel(permissions)==1
        permissions=permissions{1};
    end
    end

    function out=prms_pc_fun_(file)
        % windows has file permissions AND attributes
        % permissions are also very complex

        attribs=get_attributes(file);
        bReadOnly=ismember('R',attribs);

        out=Sys.run(['icacls ' file]);
        str='All users have full control';
        if bReadOnly && contains(out{1},str)
            out='444';
        elseif contains(out{1},str)
            out='777';
        else
            error(['WRITE CODE: unhandled windows permissions output' newline strjoin(out,newline)]);
        end

        function out=get_attributes(file)
        out=Sys.run(['attrib ' file]);
        out=out{1};
        out=strsplit(out);
        out=out(1:end-1);
        out=out(~cellfun('isempty',out));
        end
    end
    function bCell=check_cell_src_dest(src,dest)
        bCell  = iscell(src) || iscell(dest);
        if bCell
            bGdCell= iscell(src) && iscell(dest) && ...
                    length(src) == length(dest) && ...
                    all(cellfun(@ischar,dest)) && ...
                    all(cellfun(@ischar,src));
            if  ~bGdCell
                error('Cell formatting is incorrect');
            end
            notExist= ~cellfun(@FilDir.exist,src);
            if any(notExist)
                error(['The following files do not exist:' newline ...
                       strcat(['    ',Vec.col(src(notExist)) ]) ...
                      ]);
            end
        end
    end

end
end
