classdef Path < handle
methods(Static)
    function oldPath=add(pathlist,defpath)
        pathlist=unique(pathlist);

        dirs='';
        if Sys.islinux()
            for i = 1:length(pathlist)
                p=Path.gen(pathlist{i});
                dirs=[dirs ':' p];
            end
            %dirs=dirs(1:end-1);
            dirs=[defpath pathsep dirs];
        else
            dirs=Px.gen_path(pathlist);
            dirs=[defpath pathsep dirs];
        end
        dirs=strrep(dirs,';',pathsep);
        assignin('base','dirs',dirs)
        try
            %oldPath = addpath(dirs, '-end');
            oldPath = matlabpath(dirs);
        catch
            warning('Problem adding path. Likley a broken sym link.');
        end
    end
    function out=gen(dire)
        if isunix
            out=Path.genCmd_(dire);
        else
            out=Path.genDefault_(dire);
        end
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
        if exist('dire','var') && ~isempty(dire)
            old=cd(dire);
        end
        notDirs={'.julia*','\.git*','\.svn*','private*','\.ccls-cache/*','_AR*','_old*','+*','@*','__MACOSX*','.DS_*'};
        if endsWith(dire,filesep)
            dire=dire(1:end-1);
        end

        if Sys.isInstalled('fd')
            cmd=['fd . -L --color never --type d '];
            for i =1:length(notDirs)
                cmd=[cmd  '-E ' '''' notDirs{i} ''' '];
            end
            cmd=[cmd '--base-directory .'  ];
        else
            cmd='find -L "$(pwd -P)" -type d';
            for i = 1:length(notDirs)
                cmd=[cmd ' -not -path ''''"$(pwd -P)"''**/' notDirs{i} ''''];
            end
        end

        [~,out]=unix(cmd);
        if ~isempty(out)
            out(end)=[];
            out=strrep(out,newline,[':' dire filesep]);
            out=[dire filesep out];
        end

        if exist('old','var') && ~isempty(old)
            cd(old);
        end
    end

    function p = genDefault_(d)
        % String Adoption
        %try
        %    d = convertStringsToChars(d);
        %end

        if nargin==0,
            p = Px.gen_path(fullfile(matlabroot,'sbin'));
        if length(p) > 1, p(end) = []; end % Remove trailing pathsep
            return
        end

        % initialise variables
        classsep = '@';  % qualifier for overloaded class directories
        packagesep = '+';  % qualifier for overloaded package directories
        p = '';           % path to be returned

        % Generate path based on given root directory
        if iscell(d)
            f=cellfun(@dir,d,'UniformOutput',false);
            files=vertcat(f{:});
            p=[p strjoin(d,pathsep) pathsep];
            bCell=1;
        else
            files = dir(d); % XXX BOTTLENECK
            p = [p d pathsep];
            bCell=0;
        end
        if isempty(files)
            return
        end

        % Add d to the path even if it is empty.

        % set logical vector for subdirectory entries in d
        isdir = logical(cat(1,files.isdir));
        %
        % Recursively descend through directories which are neither
        % private nor "class" directories.
        %
        dirs = files(isdir); % select only directory entries from the current listing
        dirs=dirs(3:end);

        if ~bCell
            for i=1:length(dirs)
                dirname = dirs(i).name;
                if ~strncmp( dirname,classsep,1) && ~strncmp( dirname,packagesep,1) && ~strcmp( dirname,'private') && isempty(regexp(dirname,'^(_Ar|_old|\.svn|\.git|\.hg|^\.\.$)'))
                    p = [p Px.gen_path([d filesep dirname])]; % recursive calling of this function.
                end
            end
        else
            lastdire='';
            for i=1:length(dirs)
                dirname = dirs(i).name;
                dire    = dirs(i).folder;
                if ~strcmp(dire,lastdire)
                    bAdd=~strcmp( dirname,'.') && ~strcmp( dirname,'..') && ~strncmp( dirname,classsep,1) && ~strncmp( dirname,packagesep,1) && ~strcmp( dirname,'private') && isempty(regexp(dirname,'^(_Ar|_old|.svn|.git|.hg)'));
                end
                if bAdd
                    for j = 1:length(d)
                        p = [p Px.gen_path([ dire filesep dirname]) ]; % recursive calling of this function
                    end
                end
                lastdire=dirname;
            end
        end
    end
end
end
