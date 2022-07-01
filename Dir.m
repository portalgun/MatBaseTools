classdef Dir < handle & FilDir
methods(Static)
%% LIST
    function out=current()
        db=dbstack;
        out=Dir.parent(which(db(2).file));
    end
    function out=home()
        % XXX
        try
            out=Dir.homeC_();
        catch
            out=Dir.homeCmd_();
        end
    end
    function out=isempty()
        dirs=dir(dire);
        out=numel(dirs) <= 2;
    end
    function own(usr,dire)
        if Sys.isunix()
            cmd=['chown -R ' usr ' ' dire];
        else
            error();
        end
        [status,msg]=Sys.command(cmd);
        if status
            disp(msg);
        end

    end
    function [status,msg]=addWrite(dire,bRecursive)
        if nargin < 2 || isempty(bRecursive)
            bRecursive=false;
        end
        bUnix=isunix();
        if iscell(dire)
            cmd=strjoin(cellfun(@(x) getCmdFun(x,bUnix,bRecursive),dire,'UniformOutput',false),' ');
        else
            cmd=getCmdFun(dire,bUnix,bRecursive);
        end

        [status,msg]=Sys.command(cmd);
        if nargout > 1 && status
            disp(msg);
        end
        function cmd=getCmdFun(dire,bUnix,bRecursive)
            if bUnix()
                if bRecursive
                    cmd=['chmod -R +w ' dire ';'];
                else
                    cmd=['chmod +w ' dire ';'];
                end
            else
                error();
            end
        end
    end
    function [status,msg]=rmWrite(dire,bRecursive)
        if nargin < 2 || isempty(bRecursive)
            bRecursive=false;
        end
        bUnix=isunix();
        if iscell(dire)
            cmd=strjoin(cellfun(@(x) getCmdFun(x,bUnix,bRecursive),dire,'UniformOutput',false),' ');
        else
            cmd=getCmdFun(dire,bUnix,bRecursive);
        end

        [status,msg]=Sys.command(cmd);
        if nargout > 1 && status
            disp(msg);
        end
        function cmd=getCmdFun(dire,bUnix,bRecursive)
            if bUnix()
                if bRecursive
                    cmd=['chmod -R -w ' dire ';'];
                else
                    cmd=['chmod -w ' dire ';'];
                end
            else
                error();
            end
        end
    end
    function [fnames,fnamesfull]=re(dire,str)
        [fnames,fnamesfull]=Dir.re_(dire,str,1,1);
    end
    function [fnames,fnamesfull]=reDirs(dire,str)
        [fnames,fnamesfull]=Dir.re_(dire,str,1,0);
    end
    function [fnames,fnamesfull]=reFiles(dire,str)
        if iscell(dire)
            [fnames,fnamesfull]=cellfun(@(x) Dir.reFiles(x,str),dire,'UniformOutput',false);
            fnames=vertcat(fnames{:});
            fnames=vertcat(fnamesfull{:});
            return
        end
        [fnames,fnamesfull]=Dir.re_(dire,str,0,1);
    end
    function out=parent(dire)
        if iscell(dire)
            out=cellfun(@Dir.parent,dire,'UniformOutput',false);
            return
        end
        dire=Dir.parse(dire);
        if strcmp(dire,filesep)
            out='';
            return
        elseif endsWith(dire,filesep)
            dire=dire(1:end-1);
        end
        if ~ismember(dire,filesep)
            out='./';
            return
        end
        spl=strsplit(dire,filesep);
        out=strjoin(spl(1:end-1),filesep);
        if ~endsWith(out,filesep)
            out=[out filesep];
        end
    end
    function name=parentName(dire)
        if iscell(dire)
            name=cellfun(@Dir.parentName,dire,'UniformOutput',false);
            return
        end
        par=Dir.parent(dire);
        if isempty(par)
            name='';
            return
        end

        spl=strsplit(par,filesep);
        name=spl{end-1};
        if isempty(name)
            name=filesep;
        end
    end
    function [dirs,dirsfull]=dirs(dire)
        %if iscell(dire)
        %    [dirs,dirsfull]=cellfun(@Dir.dirs,dire,'UniformOutput',false);
        %    return
        %end
        dumbDirs={'.','..'};
        if ~endsWith(dire,filesep)
            dire=[dire filesep];
        end
        if ~(exist(dire,'dir')==7)
            error(['Directory does not exist: ' dire]);
        end
        s=dir(dire);
        dirs=transpose({s.name});
        dirs(~[s.isdir])=[];

        dirs(ismember(dirs,dumbDirs))=[];
        dirsfull=strcat(dire,dirs,filesep);
    end
    function [fnames,fnamesfull]=files(dire)
        if nargin < 1 || isempty(dire)
            dire=pwd;
        end
        if ~isequal(dire(end),filesep)
            dire=[dire filesep];
        end
        if ~(exist(dire,'dir')==7)
            error(['Directory does not exist: ' dire]);
        end
        %out=FilDir.find(dire,re,1,'f'); % XXX doesn't work for hidden

        s=dir(dire);
        fnames=transpose({s.name});
        fnames([s.isdir])=[];
        fnamesfull=strcat(dire,fnames);
    end
    function [expFcnListAll] = getNonStdDeps(directory,bLong,bRecursive,bLoop)
        %list all dependencies of a given directory
        directory='/home/dambam/Cloud/Code/mat/projects/daveMatTB';
        names=rdir([directory,'/**/*.m']);
        names=transpose({names.name});

        fcnListAll=cell(0,1);
        for i = 1:length(names)
            [~,name,~] = Fil.parts(names{i});
            [~,expFcnList] = Fun.getNonStdDeps(name,bLong,bRecursive,bLoop);
            expFcnListAll={expFcnListAll; expFcnList};
        end

        %REMOVE DUPLICATE
        expFcnListAll=unique(expFcnListAll);
    end
%% RM
    function out=rm_rf(dire,bDry)
        if nargin < 2
            bDry=false;
        end
        if Fil.is(dire)
            if bDry
                disp(['dry file delete ' dire]);
            else
                delete(file);
            end
            return
        elseif FilDir.isLink(dire)
            if bDry && nargout < 1
                disp(['dry unlink ' dire]);
            else
                FilDir.unlink(dire);
            end
            return
        elseif ~exist(dire,'dir')
            error(['File/directory ' dire ' does not exist.']);
        end

        dire=Dir.parse(dire);
        dirsAll =FilDir.find(dire,'.*',[],'d');
        if ~iscell(dirsAll)
            dirsAll={dirsAll};
        end
        if isempty(dirsAll{1})
            bLnk=[];
            dirs={};
            dlnks={};
        else
            bLnk=cellfun(@(x) FilDir.isLink([dire x]),dirsAll);
            dirs=flipud(dirsAll(~bLnk)); % flip so subdirectories first
            dlnks=dirsAll(bLnk);
        end

        if ~bDry && ~isempty(dirsAll{1})
            lst=strjoin(strcat({'   '},dirsAll),newline);
            disp(['From ' dire]);
            text=[ '--remove the following directories and their contents?' newline lst newline];
            r=Input.yn(text);
            if ~r
                return
            end
        end
        dirs=strcat(dire,dirs);
        dlnks=strcat(dire,dlnks);

        % UNLINK FIRST SO DON'T DELETE SOURCE FILES
        % PARENTS FIRST SO NO FLIP
        for i = 1:length(dlnks)
            if bDry & nargout < 1
                disp(['dry unlink ' dlinks{i}]);
            else
                FilDir.unlink(dlnks{i});
            end
        end
        % FIND FILES AFTER UNLINKING
        files=FilDir.find(dire,'.*',[],'f');
        if ~isempty(files)
            files=strcat(dire,files);
        end
        for i = 1:length(files)
            if bDry & nargout < 1
                disp(['dry file delete ' files{i}]);
            else
                delete(files{i});
            end
        end
        for i =1:length(dirs)
            if bDry & nargout < 1
                disp(['dry dir delete ' dirs{i}]);
            else
                rmdir(dirs{i});
            end
        end
        rmdir(dire);
        if nargout > 1
            out=[dlnks; files; dirs];
        end
    end
    function out=rmBrokenLinks(dire)
        % XXX TEST
        nodes=dir(dire);
        nodes=nodes(3:end);
        nodes=Vec.col({nodes.name});
        nodes=strcat(dire,nodes);
        for i = 1:length(nodes)
            if FilDir.islink(nodes{i}) && FilDir.islinkbroken(nodes{i})
                FilDir.unlink(nodes{i});
            end
        end
    end


%% LIST MANY
    function [fnames,fnamesfull]=reMany(dire,str)
        [fnames,fnamesfull]=Dir.re_(dire,str,1,1,'find');
    end
    function [fnames,fnamesfull]=reDirsMany(dire,str)
        [fnames,fnamesfull]=Dir.re_(dire,str,1,0,'find');
    end
    function [fnames,fnamesfull]=reFilesMany(dire,str)
        [fnames,fnamesfull]=Dir.re_(dire,str,0,1);
    end
    function [dirs,dirsfull]=filesMany(dire)
        [fnames,fnamesfull]=Dir.re_(dire,'.*',0,1,'find');
    end
    function [dirs,dirsfull]=dirsMany(dire)
        [dirs,dirsfull]=Dir.re_(dire,'.*',1,0,'find');
    end
%% FIND
    function out=find(dire,re,depth)
        if nargin < 3
            depth=[];
        end
        if nargin < 2
            re='.*';
        end
        out=FilDir.find(dire,re,depth,'d');
    end
    function dire=where()
        %% XXX MOVE  TO FUNC
        a=dbstack('-completenames');
        a=transpose({a.file});
        dire=a{2};
        dire=fileparts(dire);
    end
%% MKDIR
    function varargout=mk(dire)
    %bNew=varargout=mk(dire)
        bNew=Dir.mk_p_(dire,0);
        if nargout==1
            varargout{1}=bNew;
        end
    end
    function varargout=mk_p(dire)
    %bNew=mk_p()
        bNew=Dir.mk_p_(dire,1);
        if nargout==1
            varargout{1}=bNew;
        end
    end
%% CHECK
    function out=exist(dire)
        out=exist(dire,'dir')==7;
    end
    function out=highest(dire)
        parts=Dir.split_(dire);
        if any(cellfun(@isempty,parts))
            error(['Double fileseparator in var: ' dire]);
        end

        if parts{1}==filesep
            cur=parts{1};
        else
            cur=[parts{1} filesep];
        end
        if ~exist(cur,'dir')
            out='';
            return
        end
        for i = 2:length(parts)
            last=cur;
            cur=[cur parts{i} filesep];
            if ~exist(cur,'dir')
                out=last;
                return
            end
        end
        out=cur;
    end
    function [out,code]=check(dire,bMk,bPrint)
    %function [out,code]=check(dire,bMk,bPrint)
    % bPrint=2 -> error

        if ~exist('bMk','var') || isempty(bMk)
            bMk=0;
        end
        if ~exist('bPrint','var') || isempty(bPrint)
            bPrint=0;
        end
        dire=Dir.parse(dire);

        code='';
        f=Fil.exist(dire(1:end-1));

        hst=Dir.highest(dire);
        [r,w,x]=FilDir.perms(hst);

        if strcmp(hst,Dir.last(dire)) && r && w && x;
            out=true;
            return
        end
        % XXX SRV
        if r && w && x && bMk && ~f
            Dir.mk_p(dire);
            out=true;
            return
        else
            out=false;
        end
        if f
            % file not dir
            code=[code 'f'];
        elseif r && x && w && ~bMk
            % doesnt exist
            code=[code 'e'];
        end

        %perms
        if ~r
            code=[code 'r'];
        end
        if ~x
            code=[code 'x'];
        end
        if ~w
            code=[code 'w'];
        end
        if ~out && bPrint==2
            str=Dir.code_text(code,dire,hst);
            error(str);
        end
        if ~out && bPrint
            str=Dir.code_text(code,dire,hst);
            disp(str);
        end
    end
%% CHAR
    function out=last(dire)
        spl=strsplit(dire,filesep);
        out=[spl{end-1} filesep];
    end
    function out=parseRev(dire)
        if iscell(dire)
            out=cellfun(@rev_fun,dire,'UniformOutput',false);
        else
            out=rev_fun(dire);
        end
        function dire= rev_fun(dire)
            while endsWith(dire,filesep)
                dire=dire(1:end-1);
            end
        end
    end
    function out=parse(dire)
        out=dire;
        if isempty(dire)
            return
        end
        if ispc
            out=strrep(out,'/',filesep);
            sep=[filesep filesep];
        else
            out=strrep(out,'\',filesep);
            out=regexprep(out,'^[a-zA-Z]{1}:','');
            sep=filesep;
        end
        out=regexprep(out,[sep '{2,}'],filesep);
        if out(end) ~= filesep
            out=[out filesep];
        end
    end



end
%% PRIVATE
methods(Static, Access=private)
    function out=homeC_()
        out=home_cpp();
    end
    function out=homeCmd_()
        if isunix()
            [~,out]=unix('echo $HOME');
            out=strrep(out,newline,'');
        else
            out='Y:'; % XXX ADD TO CONFIG
        end
    end
    function str=code_text_(code,dire,hst)
        str=['Directory: ' dire newline];
        if ismember('e',code)
            str=['    Highest existing directory ' hst newline];
        else
            str=['Sub-directory ' hst newline];
        end
        if ismember('x',code)
            str=[str '    No execute perms' newline];
        end
        if ismember('r',code)
            str=[str '    No read Perms' newline];
        end
        if ismember('w',code)
            str=[str '    No write Perms' newline];
        end
    end
    function [fnames,fnamesfull]=re_(fpath,re,bDir,bFiles,method)
        fpath=Dir.parse(fpath);
        if exist('method','var') && strcmp(method,'find')
            if bDir && ~bFiles
                t='d';
            elseif bFiles && ~bDir
                t='f';
            else
                t=[];
            end
            fnames=FilDir.find(fpath,re,1,t);
            fnamesfull=strcat(fpath,fnames);
        else
            fnames=Dir.files(fpath);
            fnames = fnames( ~cellfun('isempty', regexp(fnames,re)));
            fnamesfull=strcat(fpath,fnames);
        end

    end
    function parts=split_(dire)
        parts=strsplit(dire,filesep);
        if isempty(parts{1})
            parts{1}=filesep;
        end
        if isempty(parts{end})
            parts(end)=[];
        end
    end
    function bNew=mk_p_(dire,bP)
        parts=Dir.split_(dire);

        if any(cellfun(@isempty,parts))
            error(['Double fileseparator in var: ' dire]);
        end

        if parts{1}==filesep
            cur=parts{1};
        else
            cur=[parts{1} filesep];
        end
        bNew=0;
        if ~exist(cur,'dir') && ~bP && length(parts)~=1
            error(['Parent directory ' cur ' does not exist']);
        elseif ~exist(cur,'dir')
            mkdir(cur);
            bNew=1;
        end

        for i = 2:length(parts)
            cur=[cur parts{i} filesep];
            if ~exist(cur,'dir') && ~bP && length(parts)~=i
                error(['Parent directory ' cur ' does not exist']);
            elseif ~exist(cur,'dir')
                mkdir(cur);
                bNew=1;
            end
        end
    end
end
end
