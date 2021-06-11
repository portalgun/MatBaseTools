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
    function out=is(fname)
        e=exist(fname,'file');
        out=e==2 || e==3;
    end
    function out=exist(fname)
        e=exist(fname,'file');
        out=e==2 || e==3;
    end
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
    function [dire,Name,Ext]=parts(name)
        [dire,~,~]=fileparts(name);
        dire=Dir.parse(dire);
        name=regexprep(name,strrep(['^' dire],'+','\+'),'');
        Name=regexprep(name,'\.[A-za-z]{1,5}$','');
        Ext=regexprep(name,Name,'');
    end
    function [out,code]=check(fname,bMk,bPrint,bX)
    %function [out,code]=check(dire,bMk,bPrint,bX)
    % bPrint=2 -> error

        if ~exist('bMk','var') || isempty(bMk)
            bMk=0;
        end
        if ~exist('bX','var') || isempty(bX)
            bX=0;
        end
        if ~exist('bPrint','var') || isempty(bPrint)
            bPrint=0;
        end

        code='';
        e=Dir.exist(fname);
        if ~e
            d=Dir.exist(fname);
        else
            d=false;
        end

        dire=Fil.parts(fname);
        hst=Dir.highest(dire);
        if ~strcmp(dire,hst)
            [dOut,dCode]=Dir.check(dire,bMk,bPrint);
            if ~dOut
                out=false;
                code=dCode;
                return
            end
        elseif ~e && ~bMk
            code='E';
        elseif d
            code='D';
        elseif ~e && bMk
            Fil.touch(fname);
            out=true;
            return
        end
        [r,w,x]=FilDir.perms(fname);
        x=x | ~bX;

        if r && w && x && ~d
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
            out=ownsUnix_(file,bDir);
        elseif ispc
            out=ownsPC__(file,bDir);
        end

    end
%% cell
    function []=append(fname,text);
        if ~exist(fname,'file')
            Fil.touch(fname);
        end
        fid = fopen(fname, 'a');
        if iscell(text)
            text=strjoin(text,newline);
        end
        fprintf(fid, '%s', text);
        fclose(fid);
    end
    function write(fname,text,bOverwrite)
        if ~exist('bOverwrite','var') || isempty(bOverwerite)
            bOverwrite=false;
        end
        if exist(fname,'file') && ~bOverwrite
            error(['file ' fname ' exists. Use Fil.rewrite if needed.'])
        end
        fid = fopen(fname, 'w');
        if iscell(text)
            text=strjoin(text,newline);
        end
        fprintf(fid, '%s', text);
        fclose(fid);
    end
    function []=rewrite(fname,text);
        if ~exist(fname,'file')
            Fil.touch(fname);
        end
        fid = fopen(fname, 'w');
        if iscell(text)
            text=strjoin(text,newline);
        end
        fprintf(fid, '%s', text);
        fclose(fid);
    end
    function lines=cell(fname)
        fid = fopen(fname);
        tline = fgetl(fid);
        lines={};
        while ischar(tline)
            lines{end+1}=tline;
            tline = fgetl(fid);
        end
        fclose(fid);
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
end
end

