classdef Dir < handle & FilDir
methods(Static)
%% LIST
    function out=home()
        % XXX
        out=Dir.homeC_();
        %out=Dir.homeCmd_();
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
        dire=Dir.parse(dire);
        spl=strsplit(dire,filesep);
        out=strjoin(spl(1:end-1),filesep);
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
        dirsfull=strcat(dire,dirs);
    end
    function [fnames,fnamesfull]=files(dire)
        if ~isequal(dire(end),filesep)
            dire=[dire filesep];
        end
        if ~(exist(dire,'dir')==7)
            error(['Directory does not exist: ' dire]);
        end
        s=dir(dire);
        fnames=transpose({s.name});
        fnames([s.isdir])=[];
        fnamesfull=strcat(dire,fnames);
    end
    function [expFcnListAll] = getNonStdDeps(directory,bLong,bRecursive,bLoop)
        %list all dependencies of a given directory
        directory='/home/dambam/Cloud/Code/mat/projects/daveMatTB';
        names=rdir([directory,'/**/*.m']);
        names={names.name}';

        fcnListAll=cell(0,1);
        for i = 1:length(names)
            [~,name,~] = Fil.parts(names{i});
            [~,expFcnList] = Fun.getNonStdDeps(name,bLong,bRecursive,bLoop);
            expFcnListAll={expFcnListAll; expFcnList};
        end

        %REMOVE DUPLICATE
        expFcnListAll=unique(expFcnListAll);
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
        if ~exist('depth','var')
            depth=[];
        end
        if ~exist('dire','var')
            dire=[];
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
        if isempty(spl{end})
            out=[spl{end-1} filesep];
        else
            out=spl{end};
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
            Fnames = dir(fpath);
            Fnames(1:2)=[];
            if bDir & ~bFiles
                inds=vertcat(Fnames.isdir);
            elseif bDir & bFiles
                inds=ones(size(Fnames));
            else
                inds=~vertcat(Fnames.isdir);
            end
            fnames = transpose({Fnames.name});
            fnames = fnames( ~cellfun('isempty', regexp(fnames(inds),re)));
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
        cur
        bNew=0;
        if ~exist(cur,'dir') && ~bP && length(parts)~=1
            error(['Parent directory ' cur ' does not exist']);
        elseif ~exist(cur,'dir')
            mkdir(cur);
            bNew=1;
        end

        for i = 2:length(parts)
            cur=[cur parts{i} filesep];
            if ~exist(cur,'dir') ~bP && length(parts)~=i
                error(['Parent directory ' cur ' does not exist']);
            elseif ~exist(cur,'dir')
                mkdir(cur);
                bNew=1;
            end
        end
    end
end
end
