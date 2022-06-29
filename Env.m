classdef Env < handle
properties
    configDir
    hostname
    os
    prjs
    vars
    seen=cell(0,2)
end
properties(Constant)
    % $$
    eRE='\$\$[A-Z]+([A-Z_]+[A-Z]*)*'
    % @
    mRE=['@[A-Za-z][A-Za-z0-9]*[^/' char(123) ']*'] % 123 = left bracket % XXX make more robust
    % @{}
    mmRE='@[A-Z]+\{.*\}'
end
methods(Access=private)
    function obj=Env(configDir,prjs,hostname,os)
        obj.configDir=configDir;
        if ~exist('hostname','var') || isempty(hostname)
            obj.hostname=Sys.hostname();
            obj.os=Sys.os;
        else
            obj.hostname=hostname;
        end
        if  exist('os','var') && ~isempty(os)
            obj.os=os;
        elseif isempty(obj.os)
            obj.os=Sys.os;
        end

        if exist('prjs','var') && ~isempty(prjs) && ~iscell(prjs)
            obj.prjs={prjs};
        elseif exist('prjs','var') && ~isempty(prjs)
            obj.prjs=prjs;
        end

        Opts=obj.read_();
        if numel(fieldnames(Opts)) == 0
            return
        end

        obj.set(Opts);
    end
    function Opts=read_(obj)
        scopes=['root', fliplr(Vec.row(obj.prjs))];
        if ~iscell(scopes)
            scopes={scopes};
        end

        types={''};
        if ~isempty(obj.os)
            types=[types obj.os];
        end
        if ~isempty(obj.hostname)
            types=[types obj.hostname];
        end

        Opts=dict(true);
        for i = 1:length(scopes)
        for j = 1:length(types)
            Opts=obj.read_fun(obj.configDir,Opts,scopes{i},types{j});
        end
        end

    end
    function Opts=read_fun(obj,dire,Opts1,scope,type)
        if ~isempty(type)
            fname=[dire scope '.' type '.cfg'];
        else
            fname=[dire scope '.cfg'];
        end

        if Fil.exist(fname)
            ind=ismember(obj.seen(:,1),fname);
            if any(ind)
                Opts2=copy(obj.seen(ind,2));
            else
                Opts2=Cfg.read(fname);
                obj.seen{end+1,1}=fname;
                obj.seen{end,2}=Opts2;
            end

            % RENAME PRJ VARS
            flds=fieldnames(Opts2);
            if ~strcmp(scope,'root')
                for i = 1:length(flds)
                    fld=flds{i};
                    if Env.is_prj_var({fld})
                        Opts2.rename(fld,Env.prj_str(scope,fld));
                    end
                end
            end
            if (isempty(Opts1) && isempty(Opts2)) || isempty(Opts2)
                Opts=Opts1;
            elseif isempty(Opts1)
                Opts=Opts2;
            else
                Opts=Opts2.mergePref(Opts1,false,true);
            end
        else
            Opts=Opts1;
        end
    end
end
methods(Access = ?Cfg)
    function obj=set(obj,Opts)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            name=flds{i};
            val=Opts{name};
            if isnumeric(val) && numel(val) == 1
                val=num2str(val);
            end

            match=Str.RE.match(val,'@\{.*\}');
            if ~isempty(match)
                val=strrep(val,'@{',['@' name '{']);
            end

            if ischar(val)
                setenv(name,val);
                obj.vars.(name)=val;
            end
        end
    end
end
methods(Static, Access=private)
    function out=is_prj_var(fld)
        out=any(cellfun(@(x) ~all(Str.Alph.isUpper(x)),fld));
    end
    function out=prj_str(prj,fld)
        if iscell(fld)
            out=cellfun(@(x,y) [Str.Alph.upper(x) '__' Str.Alph.upper(y)],prj,fld,'UniformOutput',false);
        else
            out=[Str.Alph.upper(prj) '__' Str.Alph.upper(fld)];
        end
    end
end
methods(Static)
    function [keys,vals] = getAll(method)
        if nargin < 1, method = 'system'; end
        method = validatestring(method, {'java', 'system'});

        switch method
            case 'java'
                map = java.lang.System.getenv();  % returns a Java map
                keys = cell(map.keySet.toArray());
                vals = cell(map.values.toArray());
            case 'system'
                if ispc()
                    %cmd = 'set "';  %HACK for hidden variables
                    cmd = 'set';
                else
                    cmd = 'env';
                end
                [~,out] = system(cmd);
                vars = regexp(strtrim(out), '^(.*)=(.*)$', ...
                    'tokens', 'lineanchors', 'dotexceptnewline');
                vars = vertcat(vars{:});
                keys = vars(:,1);
                vals = vars(:,2);
        end

        % Windows environment variables are case-insensitive
        if ispc()
            keys = upper(keys);
        end

        % sort alphabetically
        [keys,ord] = sort(keys);
        vals = vals(ord);
    end

    function out=read(prjs,configDir,hostname,os)
        if ~exist('prjs','var')
            prjs=[];
        end
        if ~exist('hostname','var')
            hostname=[];
        end
        if ~exist('os','var')
            os=[];
        end
        obj=Env(configDir,prjs,hostname,os);
        out=obj.vars;
    end
    function [out,var]=is(name)
        if iscell(name)
            var=cellfun(@(x) builtin('getenv',x),name,'UniformOutput',false);
            out=~cellfun(@isempty,var);
        else
            var=builtin('getenv',name);
            out=~isempty(var);
        end
    end
    function out=var(name,varargin)
        nameO=name;
        bCell=iscell(name);
        %name
        %if iscell(name) && numel(name)==1
        %    error
        %end
        if ~bCell
            name={name};
        end

        db=dbstack('-completenames');
        if numel(db) < 2
            caller='';
        else
            caller=db(2).file;
        end

        % NEW, NOT SURE IF GOOD IDEA
        out=cellfun(@(x) builtin('getenv', Str.Alph.upper(strrep(x,'.','__'))), name,'UniformOutput',false);
        eInd=cellfun(@isempty,out);

        if any(eInd)
            % SEE IF PRJ VARIABLE EXISTS
            [name,prj,prjDir,prjInd,pxInd,remInd,dotInd]=Env.get_prjs(caller,name); % SLOW
            if Env.is_prj_var(name)
                name=Env.prj_str(prj,name);
            end

            out=repmat({''},size(name));
            out(prjInd)=cellfun(@(x) builtin('getenv',x),name(prjInd),'UniformOutput',false);
            out(pxInd)=cellfun(@(x) builtin('getenv',x),name(pxInd),'UniformOutput',false);

            % IF NOT, CHECK IF ITS ETC
            if any(remInd)
                out=Env.etc_eval(name,prj,prjDir,out);
            end
        end

        out=Env.metaEval(out,varargin{:});
        if ~bCell && numel(out)==1
            out=out{1};
        elseif ~bCell && numel(out)~=1
            error('')
        end
    end

    function OUT=metaEval(in,varargin)
        % META PARAM REGEXP
        eRE=Env.eRE;
        mRe=Env.mRE;
        mmRE=Env.mmRE;


        % GET METAPARAMS BY TYPE
        eParams=regexp(in,Env.eRE,'match');
        eParams=cellfun(@(x) [x{:}],eParams,'UniformOutput',false);
        eEmpty=cellfun(@isempty,eParams);
        eParams(eEmpty)=repmat({''},sum(eEmpty),1);

        mmParams=regexp(in,Env.mmRE,'match');
        mmParams=cellfun(@(x) [x{:}],mmParams,'UniformOutput',false);
        mmEmpty=cellfun(@isempty,mmParams);
        mmParams(mmEmpty)=repmat({''},sum(mmEmpty),1);
        %mmParmas(~mmGd)=repmat({''},sum(~mmGd),1);

        tmp=repmat({''},size(mmParams));
        gd=~cellfun(@isempty,in);
        tmp(gd)=cellfun(@(x,y) strrep(x,y,repmat('0',1,length(y))),in(gd),mmParams(gd),'UniformOutput',false);
        %tmp=strrep(out(mmGd),mmParams(mmGd),repmat('0',1,length(mmParams)));
        tmp=strrep(tmp,'\@','__AT_REPMAN__');
        mptmp=regexp(tmp,Env.mRE,'match');
        mParams=cellfun(@(x) [x{:}],mptmp,'UniformOutput',false);
        mEmpty=cellfun(@isempty,mParams);
        mParams(mEmpty)=repmat({''},sum(mEmpty),1);
        mParams=strrep(mParams,'__AT_REPMAN__','@');

        OUT=in;
        for i = 1:length(eParams)
            if mEmpty(i) && mmEmpty(i) && eEmpty(i)
                continue
            end
            OUT{i}=Env.meta_fun_ind(in{i},mmParams{i},mParams{i},eParams{i},tmp{i},varargin{:});
        end
    end
end
methods(Static, Access=protected)
    function [name,prj,prjDir,prjInd,pxInd,remInd,dotInd]=get_prjs(caller,name)
        prjRoot=builtin('getenv','PX_PRJS_ROOT');
        dires=cellfun(@(x) Str.Alph.upper(x),Dir.dirs(prjRoot),'UniformOutput',false); % SLOISH

        prj=repmat({''},size(name));
        prjDir=repmat({''},size(name));

        prjInd=Str.RE.ismatch(name,'^[A-Z0-9]*__.*');
        if any(prjInd)

            m=regexp(name(prjInd),'^([A-Z0-9]*)__','tokens');
            prj(prjInd)=cellfun(@(x) [x{:}{:}],m,'UniformOutput',false);
            %[~,ind]=ismember(dires,prj(prjInd))
            prjDir(prjInd)=dires(cellfun(@(x) find(ismember(dires,x),1,'first'),prj(prjInd)));
            prjDIr(prjInd)=cellfun(@Dir.parse,prjDir(prjInd),'UniformOutput',false);

        end
        pxInd=Str.RE.ismatch(name,'^PX_.*');
        if any(pxInd)
            prjDir(pxInd)='';

        end
        remInd=~pxInd & ~prjInd;

        % GET NAME OF PRJ CALLER IS IN
        if any(remInd)
            [~,p]=VE.isInPrj(caller); % SLOW!!!
            if ~isempty(p)
                prj(remInd)=repmat({p},sum(remInd),1);
                prjDir(remInd)=strcat(prjRoot,prj(remInd),filesep);
            end
        end

        dotInd=contains(name,'.');
        if any(dotInd)
            spl=cellfun(@(x) strsplit(x,'.'),name(dotInd),'UniformOutput',false);
            if numel(spl) == 1
                spl=[spl{:}];
            else
                spl=cellfun(@(x) [x{:}],spl,'UniformOutput',false);
            end
            prj(dotInd)=spl(:,1);
            prjDir(dotInd)=strcat(prjRoot,prj,filesep);
            name(dotInd)=spl(:,2);
        end

    end
    function out=etc_eval(name,prj,prjDir,out)

        % IS EXPORTED?
        [bVar,out]=Env.is(name);

        if all(bVar)
            return
        end
        name=name(~bVar);
        prj=prj(~bVar);
        prjDir=prjDir(~bVar);

        % IF NOT EXPORTED

        % READ FROM ETC CONFIG
        vars1=Env.read_config(prj,prjDir);
        vars2=Env.read_etc(prj);
        out(~bVar)=Env.apply_fun(vars1,vars2,name,out(~bVar));

    end
    function out=apply_fun(vars1,vars2,name,in)
        bEmpty1=isempty(vars1);
        bEmpty2=isempty(vars2);
        if bEmpty1 && bEmpty2
            return
        end
        if ~bEmpty1
            out=cellfun(@Env.apply_fun_ind,name,in,vars1,'UniformOutput',false);
        end
        if ~bEmpty2
            out=cellfun(@(x,y) Env.apply_fun_ind(x,y,vars2), name,in,'UniformOutput',false);
        end

    end
    function out=apply_fun_ind(name,in,vars);
        flds=fieldnames(vars);
        if ismember(name,flds);
            out=vars.(name);
        else
            out=in;
        end
    end
    function vars=read_config(prj,prjDir)
        configDir=builtin('getenv','PX_ETC');
        vars=[];
        re=strcat(prjDir,prj,'(\.(cfg|config))?');
        bInd=cellfun(@Fil.exist,strcat(prjDir,'pkg.cfg'));
        % READ FROM LOCAL CONFIG
        if ~any(bInd)
            return
        end
        files=cell(size(prjDir));
        gd=cellfun(@(x,y) ~isempty(x) && ~isempty(y) && Dir.exist(y),prj,prjDir);
        if ~any(gd)
            return
        end
        files(gd)=strcat(prjDir(gd),'pkg.cfg');
        gd=cellfun(@Fil.exist,files) & gd;
        if ~any(gd)
            return
        end
        [u,j,c]=unique(prj(gd));
        pd=prjDir(gd);
        varsU=cellfun(@(x) Env.read(x,configDir),u,'UniformOutput',false);
        %varsU=cellfun(@(x,y) Env.read(x,y),u,configDir,'UniformOutput',false);
        varsNE=cell(size(files));
        for i = 1:max(c);
            bind=c==i;
            varsNE(bind)=varsU(i);
        end
        vars=cell(size(prjDir));
        vars(gd)=varsNE;
    end

    function vars=read_etc(prj)
        [bETC,configDir]=Env.is('PX_ETC');
        if bETC
            vars=Env.read([],configDir);
        else
            vars=[];
        end
    end
    function out=meta_fun_ind(out,mmParams,mParams,eParams,tmp,varargin)


        % GET ORDER OF DIFF META PARAM TYPES
        [se,ee]=regexp(out,Env.eRE);
        [smm,emm]=regexp(out,Env.mmRE);
        [sm,em]=regexp(tmp,Env.mRE);
        [sAll,ind]=sort([se smm sm]);
        if isempty(sAll)
            bNotCell=true;
            out=strrep(out,'\@','@');
            return
        end
        eAll=[ee emm em];
        eAll=eAll(ind);
        order=repmat('0',1,length(sAll));
        order(ismember(sAll,smm))='M';
        order(ismember(sAll,sm))='m';
        order(ismember(sAll,se))='e';
        VARS=cell(length(eAll),1);
        for i = 1:length(eAll)
            VARS{i}=out(sAll(i):eAll(i));
        end

        mmInd=order=='M';
        mInd=order=='m';
        eInd=order=='e';
        NAMES=VARS;

        % GET METAPARAM NAMES
        NAMES(mmInd)=cellfun(@(x) regexprep(x(2:end),'\{.*',''),NAMES(mmInd),'UniformOutput',false);
        NAMES(mInd) =cellfun(@(x) x(2:end),NAMES(mInd),'UniformOutput',false);
        NAMES(eInd) =cellfun(@(x) x(3:end),NAMES(eInd),'UniformOutput',false);
        fsInd=cellfun(@(x) endsWith(x,filesep),NAMES);
        NAMES(fsInd)=cellfun(@(x) regexprep(x,'/+$',''),NAMES(fsInd),'UniformOutput',false);
        eStr=NAMES(eInd);
        mStr=NAMES(mInd);
        mmStr=NAMES(mmInd);

        if ~iscell(eParams)
            eParams={eParams};
        end
        if ~iscell(mmParams)
            mmParams={mmParams};
        end
        if ~iscell(mParams)
            mParams={mParams};
        end

        % GET POSSIBLE mm VLAUES
        mmCases=cellfun(@(x) ...
                    strtrim( strsplit(  ...
                    regexprep(x(1:end-1),'@[A-Z]+\{',''),',')),...
                    mmParams,'UniformOutput',false);

        %% FILL IN KEYS IF NOT PROVIDED
        if numel(varargin) > 0
            bParams=true;
            keys=varargin(1:2:numel(varargin));
            vals=varargin(2:2:numel(varargin));

            bMatch=all(ismember(keys,mStr) | ismember(keys,mmStr) | ismember(keys,eStr));  % Keys don't match
            bN=numel(sAll)==numel(varargin);
            if ~bMatch & bN
                vals=varargin;
                keys=transpose(NAMES);
                vargs=Vec.row({keys{:}; vals{:}});
            elseif ~bMatch
                keys=transpose(NAMES);
                vals=cell(1,length(sAll));
                vals(mInd)=varargin;
                vargs=Vec.row({keys{:}; vals{:}});
            else
                vargs=varargin;
            end
            params=struct(vargs{:});
        else
            bParams=false;
        end

        % EVALUATE PARAMS

        for i = 1:length(VARS)
            var=VARS{i};
            fld=NAMES{i};

            % GET VAL
            if bParams
                val=params.(fld);
            end
            if ~bParams || isempty(val)
                try
                    val=mmCases{i}{1}; % DEFAULT
                catch
                    %% NOTE PUTS BACK VARIABLE AS DEFAULT
                    val=var;
                end
            end
            if isnumeric(val)
                val=num2str(val);
            end

            % REPLACE VARS
            switch order(i)
            case 'M'
                new=[fld '_' val];
                f=[new];
                out=strrep(out,var,Env.var(f));
            case 'm'
                out=strrep(out,var,val);
            case 'e'
                f=[fld];
                out=strrep(out,var,Env.var(f));
            end

        end

        if iscell(out) && numel(out)==1
            out=out{1};
        end
        if ~isempty(Dir.highest(out))
            out=Dir.parse(out);
        end

        out=strrep(out,'\@','@');
        %vars=evalin('caller','who');
        %for i = 1:length(obj.callerVars)
        %    var=obj.callerVars{i};
        %    if ismember(var,vars)
        %        val=evalin('caller',var);
        %    else
        %        33
        %    end
        %    Opts=Cfg.rep_rec(Opts,['@' var],val);
        %end

    end
end
end
