classdef Fil < handle & FilDir
properties(Constant)
    TXT={'TXT,','CSV'}
    SPR={'XLS','XLSX','XLSM','XLSB','XLTM','XLTX','ODS'}
    SCI={'DAQ','CDF','FITS','HDF','H5','NC'}
    DTB={'SQL','JSON'}
    IMG={'BMP', 'GIF', 'HDF', 'JPEG', 'JPG', 'JP2', 'JPF', 'JPX', 'J2C', 'j2K', 'PBM', 'PCX', 'PGM', 'PNG', 'PNM', 'PPM', 'RAS', 'TIFF', 'TIF', 'XWD', 'CUR', 'ICO'}
    AUD={'AU', 'SND', 'AIFF', 'AIFC', 'FLAC', 'OGG', 'WAV', 'M4A', 'MP4'}
    MOV={'AVI', 'MJ2', 'MPG', 'ASF', 'ASX', 'WMV', 'MOV', 'MP4', 'M4V', 'MOV'}
end
methods(Static)
%% IS
    function out=exist(fname)
        e=exist(fname,'file');
        out=e==2 || e==3;
    end
    function out=is(fname)
        e=exist(fname,'file');
        out=e==2 || e==3;
    end
    function out=ism(fname)
        if isempty(Fil.ext(fname))
            fname=[fname '.m'];
        end
        e=exist(fname,'file');
        out=(e==2 || e==3) && strcmp(Fil.ext(fname),'m');
    end
    function out=ismat(fname)
        if isempty(Fil.ext(fname))
            fname=[fname '.mat'];
        end
        e=exist(fname,'file');
        out=(e==2 || e==3) && strcmp(Fil.ext(fname),'mat');
    end
    function out=isClass(fname)
        if isempty(Fil.ext(fname))
            fname=[fname '.m'];
        end
        out=Fil.ism(fname);
        if ~out; return; end
        line=Fil.getFirstLine(fname,char(37),false);
        out=startsWith(line,'classdef');
    end
    function out=isFunction(fname)
        if isempty(Fil.ext(fname))
            fname=[fname '.m'];
        end
        out=Fil.ism(fname);
        if ~out; return; end
        line=Fil.getFirstLine(fname,char(37),false);
        out=startsWith(line,'function');
    end
    function out=isScript(fname)
        if isempty(Fil.ext(fname))
            fname=[fname '.m'];
        end
        out=Fil.ism(fname);
        if ~out; return; end
        line=Fil.getFirstLine(fname,char(37),false);
        out=~startsWith(line,'function') && ~startsWith(line,'classdef');
    end
    function isDiff(fname1,fname2)
        fid1=fopen(fname1);
        fid2=fopen(fname2);
        while true
            tline1=fgetl(fid1);
            tline2=fgetl(fid2);
            if ~ischar(tline1) && ~ischar(tline2)
                out=false;
                break
            elseif  ~ischar(tline1) || ~ischar(tline2)
                out=true;
                break
            elseif ~strcmp(tline1,tline2)
                out=true;
                break
            end
        end
        fclose(fid1);
        fclose(fid2);

    end
    function out=type(fname)
        % TODO
    end
%% PARTS
    function [varargout]=parts(name)
        if iscell(name)
            varargout=cell(nargout,1);
            [varargout{:}]=cellfun(@Fil.parts,name,'UniformOutput',false);
            return
        end
        dire=Fil.fpartsdir(name);
        %dire=Dir.parse(dire);
        if dire(end) ~= filesep
            dire=[dire filesep];
        end
        varargout{1}=dire;
        if nargout == 1
            return
        end
        if ispc()
            dire=strrep(dire,'\','/');
            name=strrep(name,'\','/');
        end
        name=regexprep(name,strrep(['^' dire],'+','\+'),'');
        Name=regexprep(name,'\.[A-za-z]{1,5}$','');
        if ispc()
            dire=strrep(dire,'/','\');
        end
        varargout{2}=Name;

        if nargout == 2
            return
        end
        varargout{3}=regexprep(name,Name,'');
    end
    function out=cdate(fname)
        if iscell(fname)
            fname=strjoin(fname,'  ');
        end
        if ismac
            str=['stat -f ''%SB'' -t ''%s'' '  fname ];
            [bStat,o]=unix(str);
        else
            [bStat,o]=unix(['stat -c ''%W'' ' fname]);
        end
        if ~bStat
            out=Vec.col(cellfun(@str2double,strsplit(o(1:end-1),newline)));
        else
            out=[];
        end
    end
    function pathstr=fpartsdir(file)
        pathstr = '';

        if ~ischar(file)
            error(message('MATLAB:fileparts:MustBeChar'));
        elseif isempty(file) % isrow('') returns false, do this check first
            return;
        elseif ~isrow(file)
            error(message('MATLAB:fileparts:MustBeChar'));
        end
        if isunix    % UNIX
            ind = find(file == '/', 1, 'last');
            if ~isempty(ind)
                pathstr = file(1:ind-1);

                % Do not forget to add filesep when in the root filesystem
                if isempty(deblank(pathstr))
                    pathstr = '/';
                end
            end
        elseif ispc
            ind = find(file == '/'|file == '\', 1, 'last');
            if isempty(ind)
                ind = find(file == ':', 1, 'last');
                if ~isempty(ind)
                    pathstr = file(1:ind);
                end
            else
                if ind == 2 && (file(1) == '\' || file(1) == '/')
                    %special case for UNC server
                    pathstr =  file;
                    ind = length(file);
                else
                    pathstr = file(1:ind-1);
                end
            end
            if ~isempty(ind)
                if ~isempty(pathstr) && pathstr(end)==':' && (length(pathstr)>2 || (length(file) >=3 && file(3) == '\'))
                        %don't append to D: like which is volume path on windows
                    pathstr = [pathstr '\'];
                elseif isempty(deblank(pathstr))
                    pathstr = '\';
                end
            end
        end
    end

    function [Name]=name(fname)
        [~,Name]=Fil.parts(fname);
    end
    function [Ext]=ext(fname)
        Ext=Str.RE.match(fname,'\.[a-zA-Z0-9]+$');
        if ~isempty(Ext)
            Ext=Ext(2:end);
        end
    end
    function out=last(dire)
        %% MOVE to file
        spl=strsplit(dire,filesep);
        if isempty(spl{end})
            out=[spl{end-1} filesep];
        else
            out=spl{end};
        end
    end

%% TEMP
    function fname=tmpName(name)
        dire=Dir.parse(getenv('TMP'));
        dt=DataHash(datetime);
        fname=[dire 'tmp_' dt '.m'];
    end
%% TMP
    function name=deleteLastTmp(ext)
        if nargin < 1 || isempty(ext)
            ext=[];
        end
        [name]=Fil.get_largest_tmp_(ext);
        delete(name);
    end
    function [name,CL]=mktmp(ext,contents)
        if nargin < 2 || isempty(ext)
            contents=[];
            if nargin < 1
                ext=[];
            end
        end
        [~,name]=Fil.get_largest_tmp_(ext);
        if ~isempty(contents)
            Fil.write(name,contents);
        else
            Fil.touch(name);
        end
        if nargout > 1
            CL=onCleanup(@() delete(name));
        end

    end
%% _
    function out=find(dire,re,depth)
        if ~exist('depth','var')
            depth=[];
        end
        if ~exist('dire','var')
            dire=[];
        end
        out=FilDir.find(dire,re,depth,'f');
    end
    function out=move(fname,newname)
        if Dir.exist(newname)
            movefile(fname,newname);
        elseif endsWith(newname,filesep)
            Dir.check(newname,1,2);
            movefile(fname,newname);
        else
            [dire,~]=Fil.parts(newname);
            Dir.check(dire,1,2);
            movefile(fname,newname);
        end
    end
    function run(fname,layer)
        %Fil.isScript(fname)
        %if ~exist('layer','var') || isempty(layer)
        %    layer=1;
        %end
        %bBase=false;
        %if Fil.isScript(fname)



        %    lines=Fil.cell(fname);
        %    S=dbstack;
        %    if numel(S) == 1
        %        cmd=['run(' fname ');']
        %        evalin('base',cmd)
        %        return
        %    end
        %    first='evalin(''caller'',''run(';
        %    last=''')';
        %    cmd=[ first fname last];
        %    try
        %        evalin('caller', cmd)
        %    catch ME
        %        cmd
        %        rethrow(ME)
        %    end
        %    return

        %    for i = 1:length(lines)
        %        try
        %            evalin(caller,[lines{i} ';']);
        %        catch ME
        %            disp(lines{i});
        %            rethrow(ME);
        %        end
        %    end
        %else
        %    error('unhandled type');
        %end
    end
    function [out,code]=check(fname,bMk,bPrint,bX)
    %function [out,code]=check(dire,bMk,bPrint,bX)
    % bPrint=2 -> error
    %
    % CODES
    % RWX - NOT FIL
    % rwx - NOT DIR
    % E   - not exist
    % D   - is dir not file
    % F   - is file not dir

        if ~exist('bMk','var') || isempty(bMk)
            bMk=0;
        end
        offset=-2.14086; % XXX
        if ~exist('bX','var') || isempty(bX)
            bX=0;
        end
        if ~exist('bPrint','var') || isempty(bPrint)
            bPrint=0;
        end


        dire=Fil.parts(fname);
        if isempty(dire)
            dire=Dir.parse(pwd);
        end
        hst=Dir.highest(dire);


        [dOut,code]=Dir.check(dire,bMk,bPrint);
        if Dir.exist(fname);
            code=[code 'D'];
        end
        if ~Fil.exist(fname);
            code=[code 'E'];
            out=0;
            return
        end

        [r,w,x]=FilDir.perms(fname);

        x=x | ~bX;


        if r && w && x && ~ismember('D',code)
            out=true;
            return
        else
            out=false;
        end

        if ~r
            code=[code 'R'];
        end
        if ~x
            code=[code 'X'];
        end
        if ~w
            code=[code 'W'];
        end
        if ~out && bPrint==2
            str=Dir.Fil_(code,dire,hst);
            error(str);
        end
        if ~out && bPrint
            str=Dir.Fil_(code,dire,hst);
            disp(str);
        end
    end
    function obj=touch(fname)
        if Fil.is(fname)
            fclose(fopen(fname,'a'));
        else
            fclose(fopen(fname,'w'));
        end
    end
    function out=owns(file)

        if exist(file,'file')==7
            bDir=1;
        elseif exist(file,'file')==2
            bDir=0;
        end

        if isunix
            out=Fil.ownsUnix_(file,bDir);
        elseif ispc
            out=Fil.ownsPC_(file,bDir);
        end

    end
%% RW
    function out=isOpen(fname)
        list=fopen('all');
        out=ismember(fname,list);
    end
    function varargout=append(fname,text);
        if ~isnumeric(fname) && ~Fil.exist(fname)
            Fil.touch(fname);
        end
        if isnumeric(fname) && ~isequal(fname,-1)
            fid=fname;
        elseif ~isnumeric(fname)
            fid = fopen(fname,'a');
        end
        if iscell(text)
            text=strjoin(text,newline);
            %if endsWith(text,newline)
            %    text=[text];
            %end
        end
        fprintf(fid, '%s', text);
        if nargout > 0
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function line=getFirstLine(fname,commentChar,bError)
        if ~exist('commentChar','var')
            commentChar=[];
        end
        if ~exist('bError','var')
            bError=true;
        end
        if isnumeric(fname) && ~isequal(fname,-1)
            fid=fname;
        elseif bError && ~Fil.exist(fname)
            error([ fname ' does not exist']);
        else
            fid = fopen(fname);
        end
        tline = '';
        while ischar(tline)
            if ~isempty(tline) && ~isempty(commentChar)
                spl=strsplit(tline,commentChar);
                tline=spl{1};
            end
            if ~isempty(tline)
                tline=strtrim(tline);
            end
            if ~isempty(tline)
                line=tline;
                break
            end
            tline = fgetl(fid);
        end
    end
    function varargout=write(fname,text,bOverwrite)
        if nargin < 3 || isempty(bOverwrite)
            bOverwrite=false;
        end
        if exist(fname,'file') && ~bOverwrite
            error(['file ' fname ' exists. Use Fil.rewrite if needed.']);
        end
        if isnumeric(fname) && ~isequal(fname,-1)
            fid=fname;
        else
            fid = fopen(fname,'w');
        end

        if iscell(text)
            text=strjoin(text,newline);
        end
        fprintf(fid, '%s', text);
        if nargout > 0
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function varargout=clear(fname)
        fid=Fil.rewrite(fname,'');
        if nargout > 0
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function varargout=rewrite(fname,text);
        if ~exist(fname,'file')
            Fil.touch(fname);
        end
        if isnumeric(fname) && ~isequal(fname,-1)
            fid=fname;
        else
            fid = fopen(fname,'w');
        end
        if iscell(text)
            text=strjoin(text,newline);
        end
        fprintf(fid, '%s', text);
        if nargout > 0
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function [lines,varargout]=cell(fname,~,~)
        if ~exist(fname,'file')
            error('file does not exist');
        end
        if isnumeric(fname) && ~isequal(fname,-1)
            fid=fname;
        else
            fid = fopen(fname);
        end
        tline = fgetl(fid);
        lines={};
        while ischar(tline)
            lines{end+1,1}=tline;
            tline = fgetl(fid);
        end
        if nargout > 1
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function fid=open(fname)
        [dire,loc]=Fil.parts(fname);
        fid = fopen(fname,'a+');
        %obj.fid = fopen(obj.fname,'w+');
        %obj.CLfid=onCleanup(@() fclose(obj.fid));
    end
    function obj=close(fid)
        fclose(fid);
    end
    function obj=hasLines(fname,lines)
        if ~iscell(lines)
            lines={lines};
        end
        [flines,fid]=Fil.cell(fname);
        out=ismember(lines,flines);
        if nargout > 1
            varargout{1}=fid;
        else
            fclose(fid);
        end
    end
    function [dupNdxs,linesAll]=findDuplicateLines(fname,ignoreFlds,fld)
        lines=Fil.cell(fname);
        linesAll=lines;
        if ~exist('fld','var') || isempty(fld)
            fld=char(44); % comman
        end
        if exist('ignoreFlds','var') && ~isempty(ignoreFlds)
            for i = 1:length(lines)
                spl=strsplit(lines{i},fld);
                spl(ignoreFlds)=[];
                lines{i}=strjoin(spl,',');
            end
        end
        dupNdxs=Cell.findDuplicates(lines);
    end
    function lines=rmDuplicateLines(fname,ignoreFlds,fld)
        if ~exist('fld','var')
            fld=[];
        end
        if ~exist('ignoreFlds','var')
            ignoreFlds=[];
        end

        [ind,lines]=Fil.findDuplicateLines(fname,ignoreFlds,fld);
        for i = 1:length(ind)
            ind{i}=ind{i}(2:end);
        end
        ind=vertcat(ind{:});
        lines(ind)=[];
        Fil.rewrite(fname,lines);
    end
    function [out,varargout]=contains(fname,text)
        lines=Fil.cell(fname);
        if isempty(lines)
            out=false;
            if nargout > 1
                varargout{1}='';
            end
            if nargout > 2
                varargout{2}='';
            end
            return
        end
        ind=contains(lines,text);
        out=any(ind);
        if nargout > 1
            varargout{1}=ind;
        end
        if nargout > 2
            varargout{2}=lines;
        end
    end
end
methods(Static, Access=private)
    function str=code_text_(code,fname)
        str=['file: ' fname];
        if ismember('E',code)
            str=([str '    Does not exist ']);
        end
        if ismember('D',code)
            str=[str '    Is a directory not a file '  newline];
        end
        if ismember('R',code)
            str=[str '    No read perms '  newline];
        end
        if ismember('W',code)
            str=[str '    No write perms ' newline];
        end
        if ismember('X',code)
            str=[str '    No exec perms ' newline ];
        end
    end

    function out=ownsUnix_(file,bDir)
        if bDir
            cmd=['ls -l -d ' file ' | awk ''{print $3 " " $4}'''];
        else
            cmd=['ls -l ' file ' | awk ''{print $3 " " $4}'''];
        end
        [~,out]=unix(cmd);
        out=transpose(strsplit(out));
        out=out(~cellfun('isempty',out));
    end
    function out=ownsPC_(file,bDir)
        if file(2)~=':';
            file=[pwd filesep file];
        end
        %file=strrep(file,filesep,[filesep filesep]);

    % cmd='wmic path Win32_LogicalFileSecuritySetting where Path="C:\\windows\\winsxs" ASSOC /RESULTROLE:Owner /ASSOCCLASS:Win32_LogicalFileOwner /RESULTCLASS:Win32_SID';
        cmd=['DIR /q ' file];


        [out]=Sys.run(cmd);
        if size(out)==1
            error(['SYSTEM: ' out{1}])
        end
        out=out{4}; % XXX pretty relative, fix?
        out=strsplit(out);
        out=out(1:end-1);
        ind=startsWith(out,'\');
        out=out(ind);
    end


    function out=ownsMac_(file,bDir)
        % TODO
        out=linux_fun(file,bDir);
    end
    function [name,next]=get_largest_tmp_(ext,n)
        if nargin < 2 || isempty(n)
            n=4;
            if nargin < 1 || isempty(ext)
                ext='.tmp';
            end
        end
        dire=Dir.parse(getenv('TMP'));
        re=['tmp[0-9]{' num2str(n) '}' '\' ext];
        frmt=[dire 'tmp' '%0' num2str(n) 'd' ext];
        matches=Dir.reFiles(dire,re);
        if isempty(matches)
            num=0;
        else
            num=max( cellfun(@str2double, ...
                                        strrep( ...
                                            strrep(matches, ext, ''), ...
                                            ['tmp'],'')));
        end

        name=sprintf(frmt,num);
        if nargout > 1
            next=sprintf(frmt,num+1);
        end
    end
end
end

