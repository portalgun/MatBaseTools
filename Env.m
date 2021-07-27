classdef Env < handle
properties
    configDir
    hostname
    os
    prjs
    vars
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
        elseif isempty(obj.os) && strcmp(obj.hostname,Sys.hostname)
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
        scopes=['ENV', fliplr(Vec.row(obj.prjs))];

        types={''};
        if ~isempty(obj.os)
            types=[types obj.os];
        end
        if ~isempty(obj.hostname)
            types=[types obj.hostname];
        end

        Opts=struct();
        for i = 1:length(scopes)
        for j = 1:length(types)
            Opts=obj.read_fun(obj.configDir,Opts,scopes{i},types{j});
        end
        end

    end
end
methods(Access = ?Cfg)
    function obj=set(obj,Opts)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            name=flds{i};
            val=Opts.(name);
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
    function Opts=read_fun(dire,Opts1,scope,type)
        if ~isempty(type)
            fname=[dire scope '.' type '.config'];
        else
            fname=[dire scope '.config'];
        end


        if Fil.exist(fname)
            Opts2=Cfg.read(fname);

            % RENAME PRJ VARS
            flds=fieldnames(Opts2);
            if ~strcmp(scope,'ENV')
                for i = 1:length(flds)
                    fld=flds{i};
                    if Env.is_prj_var(fld)
                        Opts2=Struct.rename(Opts2,fld,Env.prj_str(scope,fld));
                    end
                end
            end

            Opts=Struct.combinePref(Opts2,Opts1);
        else
            Opts=Opts1;
        end
    end
    function out=is_prj_var(fld)
        out=~all(Str.Alph.isUpper(fld));
    end
    function out=prj_str(prj,fld)
        out=[Str.Alph.upper(prj) '__' Str.Alph.upper(fld)];
    end
end
methods(Static)
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
        var=getenv(name);
        out=~isempty(var);
    end
    function out=var(name,varargin)
    % GET environment
        [prj,prjDir]=Prj.name([],2);
        nameO=name;
        if contains(name,'.')
            spl=strsplit(name,'.');
            prj=spl{1};
            PRJ=[prj '.'];
            name=spl{2};
            prjDir=[Dir.parent(prjDir) prj filesep];
        else
            PRJ='';
        end

        % CONVERT
        if Env.is_prj_var(name)
            name=Env.prj_str(prj,name);
        end

        % IS EXPORTED?
        [bVar,out]=Env.is(name);

        % IF NOT EXPORTED
        if ~bVar

            % READ FROM ETC CONFIG
            [bETC,etc]=Env.is('PX_ETC');
            if bETC
                configDir=etc;
                vars1=Env.read(prj,configDir);
            end

            % READ FROM LOCAL CONFIG
            if Fil.exist([prjDir 'config'])
                configDir=prjDir;
                vars2=Env.read(prj,configDir);
            end
            if exist('vars2','var') && isfield(vars2,name)
                out=vars2.(name);
            elseif exist('vars1','var') && isfield(vars1,name)
                out=vars1.(name);
            else
                error(['Environment variable ' name ' is not set']);
            end
        end

        % META PARAM REGEXP
        eRE='\$\$[A-Z]+([A-Z_]+[A-Z]*)*';
        mmRE='@[A-Z]+\{.*\}';
        mRE=['@[A-Za-z][A-Za-z0-9]*[^/' char(123) ']*']; % 123 = left bracket % XXX make more robust


        % GET METAPARAMS BY TYPE
        eParams=Str.RE.match(out,eRE);
        mmParams=Str.RE.match(out,mmRE);
        tmp=strrep(out,mmParams,repmat('0',1,length(mmParams)));
        mParams=Str.RE.match(tmp,mRE);

        % GET ORDER OF DIFF META PARAM TYPES
        [se,ee]=regexp(out,eRE);
        [smm,emm]=regexp(out,mmRE);
        [sm,em]=regexp(tmp,mRE);
        [sAll,ind]=sort([se smm sm]);
        if isempty(sAll)
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
                    val=mmCases{1}{i}; % DEFAULT
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

        if ~isempty(Dir.highest(out))
            out=Dir.parse(out);
        end

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
