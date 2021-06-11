classdef FilDir < handle
properties(Constant)
    bC=1
end
methods(Static)
%% EXIST
    function out=exist(thing)
        out=(exist(thing,'file')==2 || exist(thing,'file')==7);
    end
%% FIND
    %%
    function out= find(dire,re,depth,ftype)
        if ~exist('depth','var')
            depth=[];
        end
        if ~exist('ftype','var')
            ftype=[];
        end
        if isunix()
            out=FilDir.findUnix_(dire,re,depth,ftype);
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
            warning(['chkPerms: file ' file ' does not exist!']);
        end

        %%
        user=Sys.whoami();
        Groups=groups();
        permissions=FilDir.prms_(file);
        owners=owns(file);
        if isunix
            [rPerm,wPerm,xPerm]=FilDir.unix_fun_(user,Groups,owners,permissions);
        elseif ispc
            [rPerm,wPerm,xPerm]=FilDir.pc_fun_(user,Groups,owners,permissions);
        end
    end
%% LINK
    function bSuccess=ln(origin,destination)
        if FilDir.bC
            bSuccess=FilDir.lnC_(origin,destination);
        elseif isunix
            bSuccess=FilDir.lnUnix_(origin,desitination);
        else
            % TODO
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
        if ~FilDir.isLink(thing)
            error(['File/directory ' thing ' is not a link.']);
        else
            % XXX need to test
            delete(thing);
        end
    end
    function bSuccess=isLink(thing)
        if FilDir.bC
            bSuccess=FilDir.isLinkC_(thing);
        else
            bSuccess=FilDir.isLinkCmd_(thing);
        end
    end
    function out=readLink(thing)
        if FilDir.bC
            out=FilDir.readLinkC_(thing);
        else
            out=FilDir.readLinkCmd_(thing);
        end
    end
end
methods(Static, Access=private)
%% LINK
    function out=lnC_(origin,destination)
        out=ln_cpp(origin,destination);
    end
    function lnUnix_(origin,destination)
        %ln(origin,destination)
        %create symbolic links
        cmd=['ln -s ' origin ' ' destination];
        [~,bSuccess]=Sys.run(cmd);
    end
    function out=isLinkC_(thing)
        out=issymlink_cpp(thing);
    end
    function out= isLinkCmd_(dire)
        if ispc
            cmd=['powershell -Command "((get-item ' dire ' -Force -ea SilentlyContinue).Attributes.ToString())"'];
            [~,out]=system(cmd);
            out=strrep(out,newline,'');
            out=contains(out,'ReparsePoint');
        %elseif Sys.islinux
        %    out=issymlink(dire);
        else
            out=~unix(['test -L ' dire]);
        end
    end
    function out=readLinkC_(thing)
        out=readlink_cpp(thing);
    end
    function out =readLinkCmd_(dire)
        if ispc
            cmd=['powershell -Command "(Get-Item ' dire ').Target'];
            [~,src]=system(cmd);
            out=strrep(src,newline,'');
            return
        elseif ismac
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
    function out=findUnix_(dire,re,depth,ftype);
        if ~exist('dire','var') || isempty(dire)
            dire=pwd;
        end
        bFd=Sys.isInstalled('fd');
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
            cmd=['fd -L --color never ' depthStr typeStr  '--regex "' re  '" --base-directory ' dire];
            [~,out]=unix(cmd);
        else
            %cmd=['find ' dire '  -regextype egrep ' depthStr typeStr '-regex ".*' filesep re '" -printf "%P\n" | cut -f 1 -d "."' ];
            cmd=['find ' dire '  -regextype egrep ' depthStr typeStr '-regex ".*' filesep re '"' ];
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

end
end
