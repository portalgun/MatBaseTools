classdef Path < handle
methods(Static)
    function out=contains(dire)
        if ~strcmp(dire,'/') && endsWith(dire,'/')
            dire=dire(1:end-1);
        end
        p=transpose(strsplit(path,':'));
        out=ismember(dire,p);
    end
    function oldPath=set(path);
        if iscell(path)
            path=strjoin(path,';');
        end
        oldPath = matlabpath(path);
    end
    function out=gen(dire)
        if isunix
            out=Path.genCmd_(dire);
        elseif iscell(dire)
            out=cellfun(@Path.genDefault_, dire,'UniformOutput',false)';
        else
            out=Path.genDefault_(dire);
        end
        assignin('base','lib',out);
    end
    function restore_default()
        matlabpath(Path.default());
    end
    function p=default()
        if isempty(which('matlab.system.internal.executeCommand'))
            bLegacy=1;
        else
            bLegacy=0;
        end

        [bPerlExists, perlPath]=Path.getPerlPath_(bLegacy);
        result=Path.parsePerlPath_(bLegacy,bPerlExists, perlPath);

        % Set the path, adding userpath if possible
        if exist( 'userpath.m', 'file' ) == 2
            p=[userpath ';' result];
        else
            p=result;
        end
    end
    function [fnames,fnamesfull]=mIn()
        p=strsplit(path(),':');
        [fnames,fnamesfull]=Dir.reFiles(p,'.*\.m');
    end
    function [fnames,fnamesfull]=matIn()
        p=strsplit(path(),':');
        [fnames,fnamesfull]=Dir.reFiles(p,'.*\.mat');
    end
end
methods(Static, Access=private)
    function [bExist,p]=getPerlPath_(bLegacy)
        if strncmp(computer,'PC',2)
            p = [matlabroot '\sys\perl\win32\bin\perl.exe'];
            bExist = exist(p,'file')==2;
        else
            [p,bExist] = Sys.which('perl');
            p = (regexprep(p,{'^\s*','\s*$'},'')); % deblank lead and trail
        end
    end
    function result=parsePerlPath_(bLegacy,bExist,p)
        % If Perl exists, execute "getphlpaths.pl"
        if bExist
            cmd = sprintf('"%s" "%s" "%s"', ...
                p, which('getphlpaths.pl'), matlabroot);
            if bLegacy
                [stat, result] = unix(cmd);
            else
                [stat, result] = matlab.system.internal.executeCommand(cmd);
            end
        else
            error(message('MATLAB:restoredefaultpath:PerlNotFound'));
        end

        % Check for errors in shell command
        if (stat ~= 0)
            error(message('MATLAB:restoredefaultpath:PerlError',result,cmd));
        end
        % Check that we aren't about to set the MATLAB path to an empty string
        if isempty(result)
            error(message('MATLAB:restoredefaultpath:EmptyPath'));
        end
    end
    function out = genCmd_(dire)
        if nargin < 1 || isempty(dire)
            old=cd(dire);
            cl=onCleanup(@() cd(old));
        end

        notDirs={'\.julia*','\.hg*','\.git*','\.svn*','private*','\.ccls-cache/*','_AR*','_old*','\+*','@*','__MACOSX*','\.DS_*'};
        dire=Dir.parseRev(dire);

        if isunix && Sys.isInstalled('fd');
            out=Path.genFd_(dire,notDirs);
        else
            out=Path.genFind_(dire,notDirs);
        end

    end
    function out=genFd_(dire,notDirs);
        %% NOTE RETURNS ABSOLUTE PATH
        cmd=['fd . -L --color never --type d'];
        cmd=[cmd ' -E ''' strjoin(notDirs,''' -E ''') ''''];
        if ~iscell(dire)
            dire={dire};
        end

        CMD=cell(length(dire),1);
        for i = 1:length(dire)
            par=Dir.parent(dire{i});
            d=strrep(dire{i},par,'');
            CMD{i}=['echo ' par d '; ' cmd ' -L -a --base-directory ' par  ' ' d ];
            %CMD{i}=['echo ' d '; ' cmd ' --base-directory ' par  ' ' d ];
        end
        cmd=strjoin(CMD,'; ');

        [~,out]=unix(cmd);
        if ~isempty(out)
            out=strsplit(strtrim(out),newline)';
        end

    end
    function out=genFind_(dire,notDirs)
        %% NOTE RETURNS ABSOLUTE PATH
        if ~iscell(dire)
            dire={dire};
        end
        excl=[' -not -path ''*/' strjoin(notDirs,''' -not -path ''**/') ''''];

        CMD=cell(length(dire),1);
        for i = 1:length(dire)
            %CMD{i}=['echo ' par d '; ' cmd ' ' d ];
            CMD{i}=['find -L ' dire{i} ' -type d' excl]; %
        end
        cmd=strjoin(CMD,'; ');
        [~,out]=unix(cmd);
        if ~isempty(out)
            out=strsplit(strtrim(out),newline)';
        end
    end

    function p = genDefault_(d)
        %% NOTE RETURNS ABSOLUTE PATH

        files = dir(d); % XXX BOTTLENECK
        if isempty(files)
            p='';
            return
        end

        re='^(@.*|\+.*|private|_Ar|\.ccls-cache|_old|\.svn|\.git|\.hg|\.+$|\.DS_|__MACOSX)';
        dirs = files(logical([files.isdir]) & ~Str.RE.ismatch({files.name},re)');

        p = [d ';'];
        for i=1:length(dirs)
            if ~endsWith(dirs(i).name,filesep)
                f=filesep;
            else
                f='';
            end
            p = [p Path.genDefault_(fullfile(d,dirs(i).name))];
        end
    end
end
end
