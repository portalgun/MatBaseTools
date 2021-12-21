classdef Cfg < handle
properties
    Options
    fname
    callerVars
end
properties(Hidden)
    othercfgs=cell(0,2)

    lvls
    blkInd

    AllC
    AllU
    sNames

    lines
    direct

    INDS
    HINDS


    KEYS={}
    keys
    vals


    bHeader
    bCellHeader
    bTemplate
    bSubplate
    bLet


    hostname
    HostInds
    OSInds

    sep=char(59)
    eq='='

    lvars
    lvals
    gvars
    gvals
    rvars
    rvals
end
methods(Static)
    function [Opts,KEYS]=read(fname,sep,eq, hostname)
        if nargin < 3
            eq=[];
            if nargin < 2
                sep=[];
            end
        end
        if nargin < 4
            hostname=[];
        end

        obj=Cfg(fname,sep,eq,[],hostname);
        Opts=obj.Options;
        if nargout > 1
            KEYS=obj.KEYS;
        end
    end
    function Opts=readLines(lines,sep,eq)
        if nargin < 3
            eq=[];
            if nargin < 2
                sep=[];
            end
        end
        obj=Cfg([],sep,eq,lines);
        Opts=obj.Options;
    end
    function Opts=readScript(CfnameC)
        try
            run(CfnameC);
            CbTmpC=false;
        catch ME
            if strcmp(ME.identifier,'MATLAB:run:CannotExecute')
                CbTmpC=true;
                CfnameC2=Fil.tmpName(CfnameC);
                copyfile(CfnameC,CfnameC2);
                run(CfnameC2);
            else
                rethrow(ME);
            end
        end

        vars=who();
        vars(ismember(vars,{'CfnameC','CfnameC2','CbTmpC','ME'}))=[];
        Opts=struct();

        for i = 1:length(vars)
            if Str.RE.ismatch(vars{i},'^ *%.*$')
                continue
            end
            str=['Opts.(vars{i})=' vars{i} ';'];
            eval(str);
        end
        if CbTmpC
            delete(CfnameC2);
        end
    end
%% ENV
    function gen_env(Opts)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
        end
    end
    function set_env(Opts)
        Env.set(Opts);
    end
end
%%%%%%%%%%%
methods(Access=?Px)
    function obj=Cfg(fname,sep,eq, lines,hostname)
        if exist('sep','var') && ~isempty(sep)
            obj.eq=sep;
        end
        if exist('eq','var') && ~isempty(eq)
            obj.eq=eq;
        end
        if exist('fname','var') && ~isempty(fname)
            obj.fname=fname;
            lines=Fil.cell(obj.fname);
        end
        if nargin >= 5
            obj.hostname=hostname;
        end
        obj.parse(lines);
        if isempty(obj.Options)
            Opts=dict(true);
            return
        end
    end
    function parseSys(obj)
        if isempty(obj.hostname)
            obj.hostname=Sys.hostname;
        end
        bMyHost=Vec.col(Str.RE.ismatch(obj.lines,['^[ \t]*HOST_' obj.hostname]));
        bOtherHost=obj.bHeader & startsWith(obj.lines,'HOST_') & ~bMyHost;
        bMyOS=obj.bHeader & Vec.col(Str.RE.ismatch(obj.lines,['^[ \t]*OS_' obj.hostname]));
        bOtherOS=obj.bHeader & startsWith(obj.lines,'OS_') & ~bMyOS;

        binds=bOtherHost | bOtherOS;
        rmInds=ind_fun(binds) | bMyOS | bMyHost;
        binds=bMyOS | bMyHost;
        obj.OSInds=ind_fun(bMyOS) & ~bMyOS;
        obj.HostInds=ind_fun(bMyHost) & ~bMyOS;
        keepInds=obj.OSInds | obj.HostInds;
        obj.lvls(keepInds)=obj.lvls(keepInds)-1;

        obj.rm(rmInds);

        function outinds=ind_fun(binds)
            inds=find(binds);
            nums=[1:length(obj.lines)]';
            outinds=zeros(size(binds));
            outinds(inds)=true;
            for i = 1:length(inds)
                ind=obj.lvls > obj.lvls(inds(i)) & nums > inds(i);
                ind(inds(i)+1:end)=cumprod(ind(inds(i)+1:end));
                outinds=outinds | ind;
            end
        end

    end
    function rm(obj,rmInds)
        obj.direct(rmInds)=[];
        obj.lines(rmInds)=[];
        obj.bHeader(rmInds)=[];
        obj.lvls(rmInds)=[];
        obj.bCellHeader(rmInds)=[];
        obj.OSInds(rmInds)=[];
        obj.HostInds(rmInds)=[];
        obj.keys(rmInds)=[];
        obj.vals(rmInds)=[];
    end
    function get_levels(obj)
        rlvls=cumsum(obj.direct);
        dlvls=nan(size(obj.direct));
        dlvls(obj.direct>0)=1;
        dlvls(obj.direct==0)=0;
        uinds=find(isnan(dlvls));
        obj.lvls=cumsum(dlvls);
        for i = 1:length(uinds)
            u=uinds(i);
            ind=find(rlvls(1:u-1) <= rlvls(u),1,'last');
            obj.lvls(u)=obj.lvls(ind);
            c=obj.lvls(u)+cumsum(dlvls(u+1:end));
            obj.lvls(u+1:end)=c;
        end
    end

    function R=get_inds(obj)
        if obj.lvls(1)~=0
            error('Unexpected indentation on first non-empty line')
        end
        INDS=zeros(length(obj.lines),max(obj.lvls+1));
        bHINDS=false(length(obj.lines),max(obj.lvls+1));
        bHINDS(1)=true;
        INDS(1)=1;
        lastlvl=1;
        for i = 2:length(obj.lines)
            lvl=obj.lvls(i)+1;
            lastlvl=min(lastlvl,lvl);
            lastrow=INDS(i-1,1:lastlvl);
            lastval=INDS(i-1,lvl);
            INDS(i,1:lastlvl)=lastrow;
            INDS(i,lvl)=lastval+1;
            bHINDS(i,lvl)=true;
            lastlvl=lvl;
        end

        obj.HINDS=INDS;
        obj.HINDS(bHINDS)=0;
        obj.INDS=INDS;
    end
    function [gvars,gvarsc,spl]=meta_get_fun(obj,re,bTwice)
        if nargin < 3
            bTwice=false;
        end
        vals=obj.vals;
        ind=~cellfun(@(x) ischar(x), vals);
        if all(ind)
            vals=repmat({''},size(ind));
        else
            vals(ind)=repmat({''},sum(ind),1);
        end
        if bTwice
            [out,mtch]=cellfun(@(x) regexp(x,re,'tokens','match'),vals,'UniformOutput',false);

            if all(cellfun(@isempty,mtch))
                gvars=[];
                gvarsc=[];
                spl=[];
                return
            end

            m=max(cellfun(@numel,out));
            out=cellfun(@(x) [x{:} repmat({''},1,m-numel(x))], out,'UniformOutput',false);

            m=max(cellfun(@numel,out));
            out=cellfun(@(x) [x{:} repmat({''},1,m-numel([x{:}]))], out,'UniformOutput',false);

            out=vertcat(out{:});
            new=cell(size(out,1),1);
            for i = 1:size(out,1)
                new{i,1}=strjoin(out(i,:),',');
                if isempty(mtch{i})
                    mtch{i}={{}};
                end
            end
            mtch=vertcat(mtch{:});
            [~,j,gvarsc]=unique(new,'rows');
            spl=out(j,:);
            gvars=mtch(j);
        else
            out=cellfun(@(x) regexp(x,re,'tokens'),vals,'UniformOutput',false);
            m=max(cellfun(@numel,out));
            out=cellfun(@(x) [x{:} repmat({''},1,m-numel(x))], out,'UniformOutput',false);
            out=vertcat(out{:});
            [gvars,~,gvarsc]=unique(out);
            gvarsc=reshape(gvarsc,size(out));
        end
    end
    function meta_set_fun(obj,gvars,gvarsc,gvals,caller)
        for b = 1:length(gvars)
            if isempty(gvars{b}) || isempty(gvals{b})
                continue
            end
            %gvars{b}
            bind=any(gvarsc==b,2);
            if all(cellfun(@isempty,obj.vals(bind)))
                continue
            end


            if isnumeric(gvals{b})
                gv=Num.toStr(gvals{b});
                obj.vals(bind)=strrep(obj.vals(bind),gvars{b},gv);
                obj.vals(bind)=cellfun(@Cfg.parseVal,obj.vals(bind),'UniformOutput',false);
            else
                obj.vals(bind)=strrep(obj.vals(bind),gvars{b},gvals{b});
            end
        end

    end
    function set_meta(obj)
        lastgvars={};
        lastgvals={};
        lastlvars={};
        lastlvals={};
        lastrvars={};
        lastrvals={};
        bSuccess=false;
        for i = 1:20
            obj.set_global_meta();
            if ~isequal(lastgvars,obj.gvars) || ~isequal(lastgvals,obj.gvals)
                lastgvars=obj.gvars;
                lastgvals=obj.gvals;
                continue
            end
            obj.set_ref_meta();
            if ~isequal(lastrvars,obj.rvars) || ~isequal(lastrvals,obj.rvals)
                lastrvars=obj.rvars;
                lastrvals=obj.rvals;
                continue
            end
            obj.set_local_meta();
            if ~isequal(lastlvars,obj.lvars) || ~isequal(lastlvals,obj.lvals)
                lastlvars=obj.lvars;
                lastlvals=obj.lvals;
                continue
            end
            bSuccess=true;
            break
        end
        if ~bSuccess
            error('cfg max recursion met');
        end
    end
    function set_local_meta(obj)
        re='(\$[a-zA-Z]+[a-zA-Z_0-9]*)';
        [gvars,gvarsc]=obj.meta_get_fun(re);
        if isempty(gvars)
            return
        end
        ggvars=cellfun(@(x) strrep(x,'$',''),gvars,'UniformOutput',false);
        ggind=ismember(ggvars,obj.keys) & ~cellfun(@isempty,ggvars);
        gvals(ggind)=obj.vals(cellfun(@(x) find(ismember(obj.keys,x) & obj.lvls==0),ggvars(ggind)));
        if isempty(gvals)
            return
        end
        obj.lvars=gvars;
        obj.lvals=gvals;
        obj.meta_set_fun(gvars,gvarsc,gvals,'local');

    end
    function set_ref_meta(obj)
        re=['&([a-zA-Z]+[a-zA-Z_0-9]*)' ...
                '\(' ...
                '([a-zA-Z]+[a-zA-Z_0-9]*)' ...
                '`(' ...
                    '[a-zA-Z]+[a-zA-Z_0-9]*', ...
                    '(?:\.', ...
                        '([a-zA-Z]+[a-zA-Z_0-9]*)' ...
                        ')*' ...
                ')'...
            '\)' ];
        vals=obj.vals;
        [gvars,gvarsc,vars]=obj.meta_get_fun(re,true);
        %gvars=regexprep(gvars,'([()./])','\\$1');
        if isempty(gvars)
            return
        end
        ind=~cellfun(@isempty,vars(:,2));
        vars(ind,2:3)=fliplr(vars(ind,2:3));
        prj=builtin('getenv','PX_CUR_PRJ_NAME');
        if isempty(prj)
            % TODO todo USE relative and abolute paths
        end
        vars(~ind,3)=repmat({prj},sum(~ind),1);

        files=vars(:,2);
        prjs=vars(:,3);
        vars=vars(:,1);


        proot=builtin('getenv','PX_PRJS_ROOT');
        prjDirs=strcat(proot,prjs,filesep);
        gvals=cell(max(gvarsc),1);
        for i = 1:length(vars)
            if isempty(vars{i})
                continue
            end
            prjFiles=[prjs{i} '.' files{i}];
            if ~ismember(prjFiles,obj.othercfgs(:,1))
                ffiles=Fil.find(prjDirs{i},files{i});
                if (iscell(ffiles) && numel(ffiles)>1)
                    error('Ambiguous resolution for reference config')
                elseif (~ischar(ffiles) && isempty(ffiles)) || (iscell(ffiles) && numel(ffiles)==0)
                    error('Reference config not found')
                end
                ffiles=[prjDirs{i} ffiles{1}];

                cfg=Cfg.read(ffiles);
                obj.othercfgs{end+1,1}=prjFiles;
                obj.othercfgs{end,2}=cfg;
            else
                cfg=obj.othercfgs{ismember(obj.othercfgs(:,1),prjFiles),2};
            end

            v=strsplit(vars{i},'.');
            v=cfg.recurse(v{:});
            if isobject(v)
                v=copy(v);
            end
            gvals{i}=v;
        end

        obj.rvars=vars;
        obj.rvals=gvals;
        obj.meta_set_fun(gvars,gvarsc,gvals,'ref');
    end
    function set_global_meta(obj)
        re='(\$\$[a-zA-Z]+[a-zA-Z_0-9]*)';
        [gvars,gvarsc]=obj.meta_get_fun(re);
        if isempty(gvars)
            return
        end
        gvals=cellfun(@(x) builtin('getenv',strrep(x,'$$','')), gvars,'UniformOutput',false);
        obj.gvars=gvars;
        obj.gvals=gvals;
        obj.meta_set_fun(gvars,gvarsc,gvals,'global');

    end
    function R=populate(obj,charstr)


        [u,i,c]=unique(fliplr(obj.HINDS),'rows','sorted');
        obj.blkInd=c;
        u=fliplr(u);
        for b = size(u,1):-1:2
            hind=ismember(obj.INDS,u(b,:),'rows');
            bind=c==b;
            v=obj.vals{hind};


            % TEMPLATE
            obj.template_fun(b);

            % CELL
            if obj.bCellHeader(hind)
                if all(cellfun(@isempty,obj.vals(bind)))
                    obj.vals{hind}=obj.keys(bind);
                else
                    obj.vals{hind}=[obj.keys(bind) obj.vals(bind)];
                end
                continue
            end

            obj.vals{hind}=dict(true,...
                                obj.keys(bind & ~obj.bTemplate & ~obj.bLet),...
                                obj.vals(bind & ~obj.bTemplate & ~obj.bLet));

            % ZERO
            if ~isempty(v)
                obj.vals{hind}{0}=v;
            end
        end
        obj.template_fun(1);

        obj.Options=dict(true, ...
                         obj.keys(c==1 & ~obj.bTemplate & ~obj.bLet), ...
                         obj.vals(c==1 & ~obj.bTemplate & ~obj.bLet) ...
                                 );

    end

    function template_fun(obj,BLOCK)

        if ~any(obj.bTemplate)
            return
        end

        %% C
        for b = 1:numel(obj.AllU)
            hind=obj.AllC==b & obj.bTemplate & obj.blkInd==BLOCK;
            sind=obj.AllC==b & obj.bSubplate & obj.blkInd==BLOCK;
            if sum(hind)==0 || sum(sind)==0
                obj.bTemplate(hind)=0;
                obj.bSubplate(sind)=0;
                continue
            elseif sum(hind) > 1
                error('Ambigous template resolution')
            end
            S=obj.vals(sind);
            for i = 1:length(S)
                S{i}=S{i}.mergePref(obj.vals{hind},false,true);
                if ~isempty(obj.vals{hind}{0}) && isempty(S{i}{0})
                    S{i}{0}=obj.vals{hind}{0};
                end
            end
            obj.KEYS{end+1}=obj.sNames{hind};
            obj.keys(sind)=strcat(obj.sNames{hind},'.',obj.sNames(sind));
            obj.vals(sind)=S;

        end
    end
    function [R,Headers]=parse(obj,lines)
        % TODO CHECK FOR DUPI

        obj.lines=lines;
        bEmpty=cellfun(@isempty,obj.lines) | Vec.col(Str.RE.ismatch(obj.lines,'^[ \t]*(%.*)$'));%
        obj.lines(bEmpty)=[];

        re='^[ \t]+';
        nl=cellfun(@(x) numel(Str.RE.match(x,re)),obj.lines);
        obj.direct=[0; diff(nl)];
        obj.bHeader=[obj.direct(2:end) > 0; false];
        obj.bCellHeader=Vec.col(Str.RE.ismatch(obj.lines,'.*:[ \t]*$'));

        obj.get_levels();

        [obj.keys,obj.vals]=cellfun(@(x) Cfg.parseLine(x,obj.sep,obj.eq) ,obj.lines,'UniformOutput',false);
        obj.parseSys();
        rmInds=cellfun(@(x,y) isempty(x) && (isempty(y) || isnan(y)),obj.keys,obj.vals);
        obj.rm(rmInds);

        % REMVOVE HOST DUPLICATES
        [u,i,c]=unique(obj.keys);
        counts=hist(c,1:max(i));
        dupuinds=find(counts > 1);
        rmInds=false(size(obj.keys));
        for d = dupuinds'
            dupind=ismember(obj.keys,u(d));
            bhost=obj.HostInds & dupind;
            bos=obj.OSInds & dupind;
            if any(bhost)
                rmInds=rmInds | dupind & ~obj.HostInds;
            elseif any(bos)
                rmInds=rmInds | dupind & ~obj.HostInds;
            end
        end
        obj.rm(rmInds);

        obj.bTemplate=~startsWith(obj.keys,'@') & contains(obj.keys,'@') & obj.bHeader;
        obj.bSubplate=contains(obj.keys,'.') & obj.bHeader;

        obj.bLet=Str.RE.ismatch(obj.keys,'^ *let +')';
        obj.keys=regexprep(obj.keys,'^ *let +','');



        All=repmat({''},size(obj.bTemplate,1),2);
        out=cellfun(@(x) strsplit(x,{'@','.'}),obj.keys(obj.bTemplate | obj.bSubplate),'UniformOutput',false);
        All(obj.bTemplate|obj.bSubplate,:)=vertcat(out{:});
        [obj.AllU,~,obj.AllC]=unique(All(:,1));
        obj.sNames=All(:,2);

        obj.get_inds();
        obj.set_meta();
        obj.populate();

    end

end
methods(Static,Hidden)
    function [key,val]=parseLine(line,sep,eq)
        line=regexprep(line,'^[ \t]*','');
        line=regexprep(line,'[ \t]*(?<!\\)(?:%|#).*','');
        %line=regexprep(line,'[ \t]*(%|#).*','');
        if endsWith(line,';') || endsWith(line,':')
            line=line(1:end-1);
        end
        if contains(line,eq)
            line=strsplit(line,eq);
            val=strtrim(strjoin(line(2:end)));
            line=line{1};
        else
            val=[];
        end
        spl=strsplit(line,sep);
        spl(cellfun(@isempty,spl))=[];
        key=cellfun(@strtrim,spl,'UniformOutput',false);
        %bValid=cellfun(@Str.Fld.isValid,key)

        val=Cfg.parseVal(val);
        if ~iscell(key) || isempty(key)
            key=[];
        else
            key=key{1};
        end


    end
    function val=parseVal(val)
        if all(ismember(val,'-.0123456789')) % CONVERT TO NUMBER
            orig=val;
            val=str2double(val);
            if isnan(val)
                val=orig;
            end
        elseif all(ismember(val,' ()^*/[]:-.0123456789')) % EVALUATE MAT & ARITHMETIC
            val=eval(val);
        end
    end
end

end
