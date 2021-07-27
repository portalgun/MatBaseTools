classdef Cfg < handle
properties
    Options
    fname
    Headers
    callerVars
end
properties(Hidden)
    sep=char(59)
    eq='='
    bP0=false;
end
methods(Access=?Px)
    function obj=Cfg(fname,sep,eq, lines)
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
        [obj.Options,obj.Headers]=obj.parse(lines);
    end
    function [R,Headers]=parse(obj,lines)
        counts=0;
        lastLvl=0;
        ROOT=cell(0);
        Headers={'_DEFAULT_'};
        headercounts=0;
        for i = 1:length(lines)
            line=lines{i};
            if isempty(line)
                continue
            end
            if startsWith(line,{char(9),' '})
                out=regexp(line,'((    |\t))');
                e=regexp(line,'[^ \t]');
                out(out >= min(e))=[];
                lvl=numel(out)+1;
            else
                lvl=1;
            end

            [key,val]=Cfg.parseLine(line,obj.sep,obj.eq);

            if lvl==1 & isempty(val) && ~isempty(key)
                headercounts=headercounts+1;
                Headers{end+1,1}=key{1};
                key={['P' num2str(headercounts)]};
            elseif lvl==1 && ~isempty(val)
                key=[{'P0'} key];
            end


            if lvl<lastLvl
                counts(lvl+1:end)=[];
            elseif lvl > lastLvl
                counts(lvl)=0;
            end
            counts(lvl)=counts(lvl)+1;
            lastLvl=lvl;
            C={key,val,{}};
            str=['ROOT{' strrep(Num.toStr(counts),',','}{3}{') '}=C;'];
            eval(str);
        end

        % RESOLVE DEFAULTS
        R=cell2structfun(ROOT);
        if isfield(R,'P0') && numel(fieldnames(R)) > 1
            D=R.P0;
            flds=fieldnames(R);
            flds(ismember(flds,'P0'))=[];
            R=rmfield(R,'P0');
            for i = 1:length(flds)
                fld=flds{i};
                [D,R.(fld)]=Cfg.merge_fun(D,R.(fld));
            end
        elseif isfield(R,'P0')
            flds=fieldnames(R.P0);
            Headers=flds;
            Rnew=struct();
            for i = 1:length(flds)
                Rnew.(['P' num2str(i)])=R.P0.(flds{i});
            end
            obj.bP0=true;
            R=Rnew;
            return
        end
        Headers(1)=[];

        function R=cell2structfun(ROOT)
            R=struct();
            R=recurse_fun(ROOT,R);
        end
        function [R,valcur]=recurse_fun(in,R,valcur)
            for i =1:length(in)
                flds=in{i}{1};
                val=in{i}{2};
                if all(ismember(val,'0123456789'))
                    val=str2double(val);
                end
                if isempty(flds)
                    continue
                end

                if length(flds)==1 && ~Str.Fld.isValid(flds{1})
                    val=flds{1};
                    flds={'FLD__'};
                end


                child=in{i}{3};
                rr=['R.' strjoin(flds,'.') ];
                str1=[ rr '=struct();' ];
                str2=['recurse_fun(child,' rr ',val);'];
                str3=[rr '= out;'];
                str4=[rr '=val;'];
                %str1
                %str2
                %str3
                %str4
                try
                    eval(str1);
                catch ME
                    disp(str1)
                    rethrow(ME);
                end
                if isempty(child)
                    try
                        eval(str4);
                    catch ME
                        disp(str4)
                        rethrow(ME);
                    end
                else
                    try
                        eval(str2);
                    catch ME
                        disp(str3)
                        rethrow(ME);
                    end
                    [out,val]=eval(str2);

                    try
                        eval(str3);
                    catch ME
                        disp(str3)
                        rethrow(ME);
                    end

                end
            end
        end
    end
    function obj=select_basic(obj)

        flds=fieldnames(obj.Options);
        ind=ismember(obj.Headers,'_DEFAULT_');
        if sum(ind) > 0
            Opts=obj.Options.(flds{ind});
            obj.Options=rmfield(obj.Options,flds{ind});
            obj.Headers(ind)=[];
        else
            Opts=struct();
        end

        flds=fieldnames(obj.Options);
        for i = 1:length(flds)
            Opts.(obj.Headers{i})=obj.Options.(flds{i});
        end
        obj.Options=Opts;
    end
    function obj=select_hostname(obj)
        hn=['HOST_' Sys.hostname];
        os=['OS_' Sys.os];
        Opts=obj.Options;
        Opts=Cfg.hostname_rec(Opts,hn,'HOST_');
        Opts=Cfg.hostname_rec(Opts,os,'OS_');
        obj.Options=Opts;
    end
    function obj=meta_eval(obj)
        Opts=struct();
        flds=fieldnames(obj.Options);
        if obj.bP0
            obj.Options=obj.meta_eval_rec(obj.Options,Opts,'\$\$',obj.fname);
            return
        end
        for i =1:length(flds)
            obj.Options.(flds{i})=obj.meta_eval_rec(obj.Options.(flds{i}),Opts,'\$\$',obj.fname);
        end
    end
    function obj=meta_eval_meta(obj)
        Opts=struct();
        callerVars={};
        [obj.Options,obj.callerVars]=obj.meta_eval_meta_rec(obj.Options,obj.Options,Opts,'\$',callerVars);
    end

end
methods(Static, Access=private)
    function [in,exitflag]=hostname_rec(in,hn,flag)
        exitflag=false;
        flds=fieldnames(in);
        rmfld={};
        for i = 1:length(flds)
            fld=flds{i};
            if strcmp(fld,hn)
                exitflag=true;
                in=in.(fld);
                return
            elseif startsWith(fld,flag)
                rmfld=[rmfld; fld];
            elseif isstruct(in.(fld))
                [in.(fld),exitflag]=Cfg.hostname_rec(in.(fld),hn,flag);
            end
        end
        if ~isempty(rmfld)
            in=rmfield(in,rmfld);
        end
    end
    function [S]=meta_eval_rec(S,Opts,chara,fname)
        flds=fieldnames(S);
        Oflds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
            if ~ismember(fld,Oflds)
                Oflds{end+1,1}=fld;
                Opts.(fld)=S.(fld);
            end
        end
        m=strrep(chara,'\','');
        for i = 1:length(flds)
            fld=flds{i};

            if ischar(S.(fld)) && contains(S.(fld),m)

                % EVALUATE DEPNDENCIES IF EXIST
                outP=Str.RE.match(S.(fld),[chara '[a-zA-Z]+[a-zA-Z_0-9]*\.']);
                if ~isempty(outP)
                    outPfull=Str.RE.match(S.(fld),[chara '[a-zA-Z]+[a-zA-Z_0-9]*\.\$[a-zA-Z]+[a-zA-Z_0-9]*']);
                    outPvar=strrep(outPfull,outP,'');
                    outPvar=outPvar(2:end);
                    P=outP(3:end-1);
                    [dire]=Fil.parts(fname);
                    file=[dire P '.config'];
                    Opts2=Cfg.read(file);
                    if isfield(Opts2,outPvar)
                        S.(fld)=strrep(S.(fld),outPfull,Opts2.(outPvar));
                    end
                end

                % HANDLE ENVIRONMENTAL VARS
                out=Str.RE.match(S.(fld),[chara '[a-zA-Z]+[a-zA-Z_0-9]*']);
                var=out(length(m)+1:end);
                env=getenv(var);
                if ~isempty(env)
                    S.(fld)=strrep(S.(fld),out,env);
                end

            elseif isstruct(S.(fld))
                S.(fld)=Cfg.meta_eval_rec(S.(fld),Opts);
            end
        end
    end
    function [S,callerVars]=meta_eval_meta_rec(SAll,S,Opts,chara,callerVars)
        flds=fieldnames(S);
        Oflds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
            if ~ismember(fld,Oflds)
                Oflds{end+1,1}=fld;
                Opts.(fld)=S.(fld);
            end
        end
        m=strrep(chara,'\','');
        for i = 1:length(flds)
            fld=flds{i};

            if ischar(S.(fld))

                % HANDLE VARIABLES LOCAL TO CONFIG FILE
                if contains(S.(fld),m)
                    out=Str.RE.match(S.(fld),[chara '[a-zA-Z]+[a-zA-Z_0-9]*']);
                    var=out(length(m)+1:end);

                    isfld=isfield(S,var);
                    if isfld
                        match=Str.RE.match(S.(var),'@\{.*\}');
                    end

                    if isfld && ~isempty(match)
                        val=strrep(match,'@{',['@' var '{']);
                        S.(fld)=strrep(S.(fld),out,val);
                    elseif isfld
                        S.(fld)=strrep(S.(fld),out,S.(var));
                    end
                end

                % GET CALLER VARS
                if contains(S.(fld),'@')
                    out=Str.RE.match(S.(fld),['@[a-zA-Z]+[a-zA-Z_0-9]*']);
                    out=out(2:end);
                    if ~ismember(out,callerVars)
                        callerVars=[callerVars; out];
                    end
                end

            elseif isstruct(S.(fld))
                S.(fld)=Cfg.meta_eval_meta_rec(SAll, S.(fld),Opts);
            end
        end
    end
    function [D,R]=merge_fun(D,R)
        dFlds=fieldnames(D);
        rFlds=fieldnames(R);
        flds=unique([dFlds; rFlds]);
        for i = 1:length(flds)
            fld=flds{i};
            if ~ismember(fld,dFlds)
                D.(fld)='@DEFAULT';
            elseif ~ismember(fld,rFlds);
                R.(fld)=D.(fld);
            elseif isstruct(D.(fld)) && isstruct(R.(fld))
                [R.(fld),D.(fld)]=Cfg.merge_fun(R.(fld),D.(fld));
            end
        end
    end
    function Opts=rep_rec(Opts,str,rep)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
            if ischar(Opts.(fld))
                Opts.(fld)=strrep(Opts.(fld),str,rep);
            elseif isstruct(Opts.(fld));
                Opts=Cfg.rep_rec(Opts.(fld),str,rep);
            end
        end
    end
end


methods(Static)
    function [key,val]=parseLine(line,sep,eq)
        line=regexprep(line,'^[ \t]*','');
        line=regexprep(line,'[ \t]*(%|#).*','');
        if endsWith(line,';')
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

    end
    function gen_env(Opts)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
        end
    end
    function set_env(Opts)
        Env.set(Opts);
    end
    function Opts=readLines(lines,sep,eq)
        if ~exist('sep','var')
            sep=[];
        end
        if ~exist('eq','var')
            eq=[];
        end
        obj=Cfg([],sep,eq,lines);
        obj.meta_eval();
        obj.select_basic();
        obj.select_hostname();
        obj.meta_eval_meta();
        Opts=obj.Options;
    end
    function Opts=read(fname,sep,eq)
        if ~exist('sep','var')
            sep=[];
        end
        if ~exist('eq','var')
            eq=[];
        end
        obj=Cfg(fname,sep,eq);
        obj.meta_eval();
        obj.select_basic();
        obj.select_hostname();
        obj.meta_eval_meta();
        Opts=obj.Options;

    end
    function Opts=readScript(CfnameC)
        run(CfnameC);
        vars=who();
        vars(ismember(vars,'CfnameC'))=[];
        Opts=struct();

        for i = 1:length(vars)
            if Str.RE.ismatch(vars{i},'^ *%.*$')
                continue
            end
            str=['Opts.(vars{i})=' vars{i} ';'];
            eval(str);
        end
    end
end
end
