classdef ArgsCon < handle
properties
   nUnm
   bUUnMatched
   bUParsed
   UsrNames
   UsrArgs
   UsrPosArgs
   UNestMatch
   nPosArgs
   OBJ
   Opts

   PIndMatched

   bUDict=false


   % META ARGS
   nout
   stack
   caller
   bNested
   bIgnoreGroups=false
   % META IP.aRGS
   KeepUnmatched=false
   IgnoreUnmatched=false
   CaseSensitive=false
   StructExpand=true
   %
   bDebug

   bNotArgIn=true

   IP
   P % P.aRSER
   Toggler

   exitflag=0
   errors={}
   ERRSTR={}
   OUT=struct
   OUT_S
   OUTUM

   name2usr=containers.Map
end
methods(Static,Access=private)
    function P=getP()
        P={ ...
           'KeepUnmatched', false, '@Args.isBinary';
           'IgnoreUnmatched',false,'@Args.isBinary';
           'CaseSensitive', true, '@Args.isBinary';
           'StructExpand', true, '@Args.isBinary'; % NOT IMPLEMENTED
           'bDebug',false,'@Args.isBinary';
           ...
           'bQuiet', false, '@Args.isBinary';
           'rmFields', {}, '@iscell';
           ...
           'nout',[],'@isnumeric';
           'stack','','@isstruct';
           'caller','','@ischar';
           'bNested',[],'@islogical';
           'bIgnoreGroups',false,'@islogical';
          };
    end
end
methods
    function [obj,out,errors,unmatched]=ArgsCon(OBJ,P,Opts,argsin)
        if isempty(Opts)
           Opts=struct();
        end
        obj.Opts=Opts;
        obj.parse_own();

        %% INIT
        if ~obj.exitflag
            obj.init(OBJ,P,argsin);
        end

        %% MAIN
        if ~obj.exitflag
            obj.main();
        end

        %% ERRORS
        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
    end
    function init(obj,OBJ,P,argsin)
        obj.OBJ=OBJ;
        obj.P=ArgsPParser(P,obj);

        if length(argsin) == 1 && isstruct(argsin{1}) && numel(argsin{1}) > 1
            obj.append_error('Detected input struct array with numel > 1.  This is likely due to nested structs in cell. Check your input and try again.');
            obj.exitflag=true;
            return
        end
        % XXX CHECK FOR DUPLICATES

        % GET USRARGS
        if length(argsin) == 1
            obj.bNotArgIn=true;
            obj.nPosArgs=0;
            switch class(argsin{1})
            case 'struct'
                % STRUCT
                if numel(fieldnames(argsin{1})) > 0
                    keys=fieldnames(argsin{1});
                    vals=struct2cell(argsin{1});

                    obj.UsrArgs=containers.Map(keys,vals);
                else
                    obj.UsrArgs=containers.Map();
                end
            case 'dict'
                obj.UsrArgs=argsin{1};
                obj.bUDict=true;
            otherwise
                if ~isempty(argsin{1})
                    error('TODO')
                end
                obj.UsrArgs=containers.Map;
            end

        else
            obj.bNotArgIn=false;

            [keys,vals,obj.UsrPosArgs,obj.nPosArgs]=Args.pairsToKeysVals(argsin{:});
            vals=cellfun(@Args.cellparsefun,vals,'UniformOutput',false);

            obj.UsrArgs=containers.Map(keys,vals);
        end
    end
    function main(obj)

        obj.P.parse();
        if obj.exitflag; return; end

        obj.parse_usr_basic();
        if obj.exitflag; return; end

        % INIT MATCHIGN
        obj.UsrNames=Vec.col(obj.UsrNames);
        fls=false(size(obj.UsrNames));
        obj.UNestMatch=fls;
        obj.bUParsed=fls;
        obj.PIndMatched=fls;
        obj.nUnm=0;

        obj.get_usr_unmatched();

        if any(obj.nUnm)
            obj.P.get_PNest();
            obj.parse_usr_nested();
        end

        obj.parse_usr_matched();
        if obj.exitflag; return; end

        if numel(obj.PIndMatched) ~= numel(obj.P.names)
            obj.expand_contract();
            if obj.exitflag; return; end
        end


        if obj.bIgnoreGroups
            obj.parse_groups();
            if obj.exitflag; return; end
        end

        %% COMPLETE
        obj.handle_unmatched;
        if obj.exitflag; return; end

        obj.convert_output();
        if obj.exitflag; return; end

        if obj.exitflag; return; end

        if obj.nout >= 3
            obj.get_toggler();
        end
    end
    function expand_contract(obj)
    % CONTRACT EXAMPLE
    % {'!trgt','trgtOpts'},                     [], '!PointDispWin3D',  1;
    % {'trgtDsp','trgtDSP','trgtOpts.trgtDsp'}, [], '',                42;
    % if tgtDsp set in trgtOpts, needs to be taken out and made its own param

        bStructs=structfun(@isstruct,obj.OUT);

        [bExpand,bContract]=obj.P.get_expand_contract_matches();

        if any(bExpand)
        %    match=obj.P.ExpandMatch(bExpand);
            % struct is preffered
            %'e'
            %pname
        end

        if any(bStructs) && any(bContract)
            cellfun(@(x,y) contract_fun(obj,x,y),obj.P.ContractMatch(bContract),obj.P.aliases(bContract));
            %names=obj.P.names(bContract);
        end
        obj.combine_errors();

        function contract_fun(obj,minds,aliases)
            PUnMatched=obj.P.names(~ismember(1:numel(obj.P.names),obj.PIndMatched));

            % thing to set
            pind=minds(1);
            name=obj.P.names{pind};
            if ~ismember(name,PUnMatched)
                return
            end

            % struct match to aliases - field to get value from
            aliases=obj.P.aliases{pind}; % tmp
            strName=aliases{minds(2)};
            spl=strsplit(strName,'.');

            % GET VALUE IF IT EXISTS
            try
                val=getfield(obj.OUT,spl{:});
            catch
                return
            end

            exiflag=obj.run_test(pind,strName,val);
            if exiflag
                return
            end

            % SET
            obj.OUT=setfield(obj.OUT,name,val);

            % RM
            str=strjoin(spl(1:end-1),'.');
            cmd=sprintf('obj.OUT.%s=rmfield(obj.OUT.%s,spl{end});',str,str);
            eval(cmd);
        end
    end
    function parse_own(obj)
        oP=Args.getP();
        flds=fieldnames(obj.Opts);
        seen={};
        for i = 1:length(flds)
            fld=flds{i};
            val=obj.Opts.(fld);
            if ismember(fld,oP(:,1))
                p=oP(ismember(oP(:,1),fld),:);
                name=p{1};
                if ismember(name,seen)
                    obj.errorMultiple(fld,true);
                    continue
                end
                seen{end+1}=name;

                fun=str2func(p{3});
                if ~fun(val)
                    obj.errorValue(fld,val,true);
                    continue
                end
                obj.(fld)=val;
            else
                obj.errorOption(fld,true);
            end
        end
    end
%% STRUCTS
%
    function parse_usr_nested(obj)
        % GET MATCHING NEST INDS IF ANY
        obj.UNestMatch=cellfun(@(x) obj.P.name2nestMatch(x),obj.UsrNames');
    end
    function parse_usr_basic(obj)
        % XXX match posargs
        % expand user options to structs if needed
        % e.g.  prop -> Opts.prop
        obj.UsrNames=keys(obj.UsrArgs);
        if obj.nPosArgs > 0
            obj.UsrPosArgs
        end

    end
    function handle_structs(obj)
        % XXX rm
        % NOTE BELOW UNUSED

        %obj.UsrNames=keys(obj.UsrArgs);
        %  change user name -> expand
        for i = 1:length(obj.UsrNames)
            uname=obj.UsrNames{i};

            if ~ismember(uname,obj.P.uNest3) % anything unmatched can be expanded
                obj.expand_struct(uname);
            end
        end

        %  change user val -> contract
        obj.UsrNames=keys(obj.UsrArgs);
        for i = 1:length(obj.P.names)
            pname=obj.P.names{i};

            % FIND ANY P THAT DOESNT HAVE A USER MATCH
            if ~ismember(pname,obj.UsrNames)
                obj.contract_struct(pname);
            end
        end
        obj.UsrNames=keys(obj.UsrArgs);
    end
    function contract_struct(obj,pname)
        % XXX rm
        % EXPAND NAME TO ALIASES WITH '.'
        pAliases=obj.name2aliases(pname);
        ind=contains(pAliases,'.');
        if isempty(pAliases) || ~any(ind)
            return
        end
        paliases=pAliases(ind);

        for j = 1:length(aliases)
            palias=paliases{j};

            spl=strsplit(palias,'.');

            % XXX
            mtchs=find(ismember(spl,obj.P.names));
            %mtchs=find(ismember(spl,obj.UsrNames));
            if isempty(mtchs)
                continue
            elseif numel(mtchs)==1
                ufld=spl{mtchs};
            else
                % XXX CHOOSE
                dk
            end
            if ~ismember(ufld,obj.UsrNames)
                continue
            end

            % GET VAL
            if obj.bUDict
                TODO
            else
                val=obj.UsrArgs(ufld);
            end

            % UNNEST STRUCT VAL
            if isa(val,'dict')
                TODO
            elseif isstruct(val)
                obj.UsrArgs(name)=val.(name);
                val=rmfield(val,name);
            end
            obj.UsrArgs(ufld)=val;

        end
    end
    function expand_struct(obj,ufld)
        % XXX rm
        val=obj.get_user_val(ufld);
        if isstruct(val)
            % expanded field
            flds=cellfun(@(x) [ufld x],Struct.getFields(val),'UniformOutput',false);
            newflds=cellfun(@(x) strjoin(x,'.'),flds,'UniformOutput',false);
            if ~any(cellfun(@(x) ismember(x,obj.P.allAliases),newflds))
                return
            end
            % unnested value
            newvals=cellfun(@(x) getfield(val,x{2:end}),flds,'UniformOutput',false);

            % assign
            obj.UsrArgs=remove(obj.UsrArgs,fld);
            for j = 1:length(newflds)
                obj.UsrArgs(newflds{j})=newvals{j};
            end
        elseif isa(val,'dict')
            TODO
        end
    end
    function get_usr_unmatched(obj)

        [obj.bUUnMatched,obj.PIndMatched]=cellfun(@(x,y,z) nest_fun(obj,x,y,z),obj.UsrNames,num2cell(obj.UNestMatch),num2cell(obj.PIndMatched));
        function [bUUm,PIM]=nest_fun(obj,uname,UNestMatch,PIM)

            if PIM >= 1
                bUUm=false;
                return
            elseif UNestMatch
                bUUm=false;
                PIM=UNestMatch;
            elseif ismember(uname,obj.P.allAliases)
                bUUm=false;
                name=obj.P.alias2name(uname);
                PIM=find(ismember(obj.P.names,name));
            else
                obj.nUnm=obj.nUnm+1;
                %fkey=['u' num2str(obj.nUnm)];
                %obj.P.f2name(fkey)=uname;
                %obj.P.alias2f(uname)=fkey;
                bUUm=true;
                PIM=0;
            end
        end
    end
%% MAIN
    function handle_unmatched(obj)
        %obj.OUTUM=containers.Map();
        %obj.get_unmatched();
        if obj.nUnm == 0
            return
        end
        UM=obj.UsrNames{obj.bUUnMatched};
        if ~obj.IgnoreUnmatched
            if iscell(UM)
                um=strjoin(UM,newline);
            else
                um=UM;
            end
            obj.append_error(sprintf('Unmatched paramters:\n%s',um));
        else
            for i = 1:length(UM)
                obj.OUTUM.(UM{i})=obj.UsrArgs(UM{i});
            end
        end
    end
    function parse_main_old(obj)
        obj.IP=inputParser;
        obj.IP.CaseSensitive=false;
        obj.IP.KeepUnmatched=true;
        obj.IP.StructExpand=true;
        cellfun(@(x,y,z) obj.IP.addParameter(x,y,z),obj.P.F,obj.P.defaults,obj.P.tests);
        try
            %obj.IP.parse(args{:});
        catch ME
            ME=Obj.struct(ME);
            m=Str.RE.match(ME.message,'[uf][0-9]+');
            %ind=str2double(m(2:end));
            msg=regexprep(ME.message,'[uf][0-9]+',obj.P.f2name(m));
            obj.append_error(msg);
        end
        obj.IP=Obj.struct(obj.IP);
    end
    function parse_usr_matched(obj)
        % INIT OUT WITH DEFAULTS
        flds=obj.P.names;
        for i = 1:length(flds)
            if contains(flds{i},'.')
                spl=strsplit(flds{i},'.');
                obj.OUT=setfield(obj.OUT,spl{:},obj.P.defaults{i});
            else
                obj.OUT.(flds{i})=obj.P.defaults{i};
            end
        end

        for u = 1:length(obj.UsrNames)
            if obj.bUUnMatched(u) || obj.bUParsed(u)
                continue
            end
            PInd=obj.PIndMatched(u);

            uname=obj.UsrNames{u};

            val=obj.get_user_val(uname);
            pname=obj.P.names(PInd);

            exiflag=obj.run_test(PInd,uname,val);
            if exiflag
                continue
            end

            % SET NESTED
            if obj.UNestMatch(u)
                newName=obj.P.name2nestName(uname,obj.UNestMatch(u));
                flds=strsplit(newName,'.');
                obj.OUT=setfield(obj.OUT,flds{:},val);
            elseif contains(pname{1},'.')
                flds=strsplit(pname{1},'.');
                obj.OUT=setfield(obj.OUT,flds{:},val);
            else
                obj.OUT.(pname{1})=val;
            end


        end
        obj.combine_errors();

    end
    function exitflag=run_test(obj,PInd,uname,val)
        exitflag=false;
        test=obj.P.tests(PInd);
        if numel(test) == 1 && ~iscell(test{1})
            test=test{1};
        end

        % TEST
        try
            test(val);
        catch ME
            valStr=Args.val2str(val);
            obj.ERRSTR{end+1}=sprintf('  %s\n    %s\n       IN\n    %s\n    %s',uname,valStr,func2str(test),ME.message);
            exitflag=true;
        end
    end
    function [val,bflag]=handle_cell(obj,val,test)
        mtch=numel(test) == 1 && iscell(test) && Str.RE.ismatch(test,'^(is)?[Cc]harcell$');

        if mtch && ischar(val)
            val={{val}};
        elseif obj.bNotArgIn && iscell(val)
            val={val};
        end

        bflag=false;
        if numel(test)== 1 && iscell(test) && Str.RE.ismatch(test,'^(is)?[Cc]el[Ss]truct') && isstruct(val)
            val={val};
        elseif ~iscell(test) && (isstruct(val) || isobject(val))
            bflag=true;
        end
        if isnumeric(val) && isempty(val)
            val={[]};
        end
    end
    function [nest,nestrmflds]=get_nest(obj)
        nest=obj.P.nest3;
        nest(cellfun(@isempty,nest(:,1)),:)=[];
        cind=cellfun(@iscell,nest(:,1));
        if any(cind)
            ind=find(cind);
            nn={};
            for i = 1:length(ind)
                names=nest{i,1};
                if iscell(names)
                    names=Vec.col(names);
                    N=numel(names);
                else
                    N=1;
                end
                val=nest(i,2:end);

                n=[names repmat(val,N,1) repmat({i},N,1)];
                nn=[nn; n];
            end
            iind=find(~cind);
            if ~isempty(iind)
                new=[nest(~cind,:) num2cell(iind)];
                nest=[new; nn];
            else
                nest=nn;
            end
        end
        nestrmflds={};
    end
    function parse_groups(obj)
        if isempty(obj.P.uGroups) || all(ismember(obj.P.uGroups(1),[0 -1]))
            return
        end
        names=obj.P.names;
        obj.UsrArgs=unique([abs(obj.uGroups) 0 1 ])';
        N=numel(obj.UsrArgs);
        n=numel(numel(obj.uGroups));
        A=[obj.UsrArgs zeros(length(obj.UsrArgs),4)];
        for i = 1:length(obj.uGroups)
            u=obj.uGroups(i);
            bGroup=cellfun(@(x) ismember(u,x),obj.groups);
            n=cellfun(@(x) ~isempty(obj.get_result(x)),names(bGroup));
            Ai=find(ismember(A(:,1),abs(u)));
            if u >= 1
                c=2; % req
            elseif u <= 0
                c=4; % optional
            end
            if isempty(n)
                n=0;
            end
            A(Ai,c)=sum(n);
            A(Ai,c+1)=numel(n);
        end
        % row
        zer=1;
        one=2;
        grps=3:size(A,1);

        % col
        req=2;
        nreq=3;
        opt=4;
        nopt=5;

        assert(~any(A(zer,req)),'Zeros marked as required: This should not happend');
        assert(~any(A(one,opt)),'Ones makred as required: This should not happend');

        % REQ
        if any(A(one,nreq) > 0 & A(one,req) < A(one,nreq));
            obj.errors{end+1}='Missing required parameters';
            obj.exitflag=true;
            % TODO LIST
        end

        %A
        %A(grps,req)
        % REQ GROUPS
        if isempty(grps)
            return
            % no groups
        end
        if all(A(grps,nreq)==0)
            % no required groups
        else
            c=A(grps,req)==A(grps,nreq) & A(grps,nreq) ~=0;
            a=A(grps,nreq) > 0 & A(grps,req) > 0 & ~c;
            if sum(c) == 1 && ~any(a)
                % good groups
            elseif sum(c) > 1
                % too many groups
                out=A(grps,1);
                out=Vec.row(out(c));
                obj.append_error(sprintf('More than one group satisfied: %s',Num.toStr(out)));
                return
            elseif sum(c) < 1
                % to few groups
                obj.append_error('No parse groups were satisfied');
                return
            elseif sum(a) > 0
                % has filled conflicting groups
                out=A(grps,1);
                out1=Vec.row(out(c));
                out2=Vec.row(out(a));
                obj.append_error(sprintf('One group %d satisfied, but conflicting parameters within other groups: %s',out1,num2str(out2)));
                return
            end
        end

        % OPT GROUPS
        if all(A(grps,nopt)==0)
            % no optional
        else
            b=A(grps,nopt) > 0 & A(grps,opt) > 0 & ~c;
            if sum(b) > 0
                out=A(grps,1);
                out1=Vec.row(out(c));
                out2=Vec.row(out(b));
                str=sprintf('Optional parameters outside of met and required group %d: %s',out1,Num.toStr(out2));
                % TODO LIST
                Error.warnSoft(str);
            end
        end
    end
    function rm_nest(obj,nestrmflds)
        % XXX RM
        % RM NESTED SO NOT USED IN UM CASES
        if isempty(nestrmflds)
            return
        end
        if any(cind)
            fun=@(x) ~isempty(x) && ~iscell(x) && any(ismember(x,nestrmflds));
            fun2=@(y) ~isempty(y) && iscell(y) && any(cellfun(@(x) fun(x) ,y));
            %
            ind=cellfun(@(x) fun(x),obj.P.nest3(:,1)) | cellfun(fun2,obj.P.nest3(:,1));
        else
            ind=cellfun(@(x) ~isempty(x) && ismember(x,nestrmflds),obj.P.nest3(:,1));
        end
        obj.P.nest3(ind,:)={[]};
    end

    function [val,nestrmflds]=parse_nested_pre(obj,uname,val,nest,nestrmflds)
        % XXX rm
        % PARSE NESTED
        if ~ismember(uname,nest(:,1))
            return
        end
        ind=ismember(nest(:,1),uname);
        o=nest{ind,2};
        if ~ischar(o) || ~isa(val,o)
            p=obj.get_other_P(o);
            opts=struct('nout',obj.nout,'caller',o,'stack',obj.stack,'IgnoreUnmatched',obj.IgnoreUnmatched,'KeepUnmatched',obj.KeepUnmatched,'bNested',true);
            [val,out]=Args.parse_internal([],p,opts,val); % HERE
            if out.exitflag && nest{ind,3}
                obj.errors=[obj.errors; out.errors];
                obj.exitflag=true;
                return
            end
        end
        nestrmflds{end+1}=uname;
    end

    function parse_nested(obj)
        % XXX RM
        umfflds=fieldnames(obj.IP.Unmatched);
        umffldsO=umfflds;
        umflds=cellfun(@(x) obj.P.f2name(x) ,umfflds,'UniformOutput',false);
        for i = 1:size(obj.P.nest3,1)
            if isempty(obj.P.nest3{i,1})
                continue
            end
            fld=obj.P.nest3{i,1};
            o=obj.P.nest3{i,2};
            [p,cls]=obj.get_nested_P(o);
            if obj.exitflag; return; end

            if iscell(fld)
                fld=fld{1};
            end
            ffld=obj.P.alias2f(fld);
            %opts=obj.get_result_f(ffld);
            opts=PStruct();

            newflds=p(:,1);
            if ~isempty(umflds)

                % POSSIBLE REP.aCEMENTS
                reps={''};
                if ~isempty(cls)
                    reps=[reps [cls '.']];
                end

                for j = 1:length(reps)
                    [umflds,umfflds]=obj.um_fun(newflds,umflds,umfflds,reps{j},opts);
                    if isempty(umflds)
                        break
                    end
                end
            end

            Opts=struct('nout',obj.nout,'caller',o,'stack',obj.stack,'IgnoreUnmatched',obj.IgnoreUnmatched,'KeepUnmatched',obj.KeepUnmatched,'bNested',true,'bIgnoreGroups',true);
            [val,out]=Args.parse_internal([],p,Opts,opts{:}); % HERE
            out=Args.parse([],p,opts{:});
            obj.set_ip_result_f(ffld,out);
        end
        %obj.IP.Unmatched
    end
    function [umflds,umfflds]=um_fun(obj,newflds,umflds,umfflds,rep,opts)
        %  XXXRM
        if ~isempty(rep)
            newflds=strcat(rep,newflds);
        end
        inds=ismember(umflds,newflds);
        if ~any(inds)
            return
        end
        flds=umflds(inds);
        fflds=umfflds(inds);
        vals=cellfun(@(x) obj.IP.Unmatched.(x),fflds,'UniformOutput',false);

        umflds(inds)=[];
        umfflds(inds)=[];
        obj.IP.Unmatched=rmfield(obj.IP.Unmatched,fflds);

        if isstruct(opts)
            cellfun(@(f,v) um_struct_fun(opts,f,v),flds,vals,'UniformOutput',false);
        elseif isa(opts,'dict')
            cellfun(@(f,v) um_dict_fun(opts,f,v),flds,vals);
        elseif iscell(opts,f,v)
            cellfun(@(f,v) um_cell_fun(opts,f,v),flds,vals);
        end
        function opts=um_struct_fun(opts,fld,val)
            if contains(fld,'.')
                spl=strsplit(fld,'.');
                opts=setfield(opts,spl{:},val);
            else
                opts.(fld)=val;
            end
        end
        function opts=um_dict_fun(opts,fld,val)
            opts(fld)=val;
        end
        function opts=um_cell_fun(opts,fld,val)
            opts{end+1}=fld;
            opts{end+1}=val;
        end
    end
%% UTIL
    function val=get_user_val(obj,name)
        if obj.bUDict
            val=obj.UsrArgs{name};
        else
            val=obj.UsrArgs(name);
        end
    end
    function aliases=name2aliases(obj,name)
        aliases=obj.P.name2aliases(name);
        if length(aliases) == 1
            aliases={};
        else
            aliases=aliases(2:end);
        end
    end
    function name=alias2name(obj,alias)
        aliases=obj.P.name2aliases(alias);
        name=aliases{1};
    end
%% RESULTS
    function out=get_result(obj,fld)
        if iscell(fld)
            fld=fld{1};
        end
        out=obj.get_result_f(obj.P.alias2f(fld));
    end
    function set_result_f(obj,DEST,fld)
        flds=strsplit(obj.P.f2name(fld),'.');
        obj.(DEST)=setfield(obj.(DEST),flds{:},obj.get_result_f(fld));

        %obj.OUT.(obj.P.f2name(flds{i}))=obj.get_result_f(flds{i});
    end
    function out=get_result_f(obj,fld)
        out=obj.IP.Results.(fld);
        %if ismember(fld,obj.IP.UsingDefaults)
        %    out=obj.IP.Results.(fld){1};
        %else
        %    out=obj.IP.Results.(fld);
        %end
    end
    function set_ip_result_f(obj,fld,val)
        obj.IP.Results.(fld)=val;
        %if ismember(fld,obj.IP.UsingDefaults)
        %    obj.IP.Results.(fld){1}=val;
        %else
        %     obj.IP.Results.(fld)=val;
        %end
    end
%% OUT
    function convert_output(obj)
        obj.OUT_S=obj.OUT;
        if isempty(obj.OBJ) && isnumeric(obj.OBJ)
            obj.OBJ=struct;
        end
        switch class(obj.OBJ)
            case 'dict'
                obj.out_as_dict();
            case 'struct'
                ;
            case 'cell'
                obj.out_as_cell();
            case 'table'
                obj.out_as_table();
            case 'Table'
                obj.out_as_Table();
            otherwise
                if isobject(obj.OBJ)
                    obj.out_as_object();
                end
        end
    end
    function out_as_object(obj);
        flds=obj.P.names;
        out=obj.OUT;
        obj.OUT=obj.OBJ;
        for i = 1:length(flds)
            obj.OUT.(flds{i})=out.(flds{i});
        end

        %flds=fieldnames(obj.OUTUM);
        %out=obj.OUTUM;
        %obj.OUT=struct();
        %for i = 1:length(flds)
        %    obj.OUTUM=out.(flds{i});
        %end
    end
    function out_as_cell(obj)
        obj.OUT=[fieldnames(obj.OUT) struct2cell(obj.OUT)];
        if isempty(obj.OUTUM)
            obj.OUTUM={};
        else
            obj.OUTUM=[fieldnames(obj.OUTUM) struct2cell(obj.OUTUM)];
        end
    end
    function out_as_dict(obj)
        obj.out_as_cell();
        obj.OUT=dict(true,obj.OUT(:,1),obj.OUT(:,2));
        if isempty(obj.OUTUM)
            obj.OUTUM=dict(true);
        else
            obj.OUTUM=dict(true,obj.OUTUM(:,1),obj.OUTUM(:,2));
        end

        %out=obj.IP.Results;
        %flds=fieldnames(out);
        %obj.OUT=dict(true);
        %for i = 1:length(flds)
        %    obj.set_result_f('OUT',flds{i});
        %end

        %flds=fieldnames(obj.IP.Unmatched);
        %obj.OUTUM=dict(true);

    end
%% TOGGLER
    function get_toggler(obj)
        out=~cellfun(@isempty,obj.P.toggles(:,1));
        n=sum(out);
        if n < 1
            return
        end
        names=cell(n,1);
        T=cell(n,1);
        vals=cell(n,1);
        for i = 1:size(obj.P.toggles,1)
            % XXX isint, isInt, isInt_e
            names{i}=obj.P.toggles{i,1};
            T{i}=obj.P.toggles{i,2};
            if isa(obj.OUT,'dict')
                vals{i}=obj.OUT{names{i}};
            elseif isstruct(obj.OUT)
                if isfield(obj.OUT,names{i})
                    vals{i}=obj.OUT.(names{i});
                else
                    vals{i}=[];
                end
            end
        end
        if isobject(obj.OBJ) && ~isa(obj.OBJ,'Table') && ~isa(obj.OBJ,'dict')
            Parent=obj.OBJ;
        else
            Parent=[];
        end
        obj.Toggler=Toggler(names,T,vals,Parent);
    end
%% ERROR
    function errors=return_errors(obj,str)
        if ~isempty(obj.errors)
            msgtext=strjoin(obj.errors,newline);
            errors = MException('Args:generalError',msgtext);
        else
            errors=[];
        end
    end
    function combine_errors(obj)
        if ~isempty(obj.ERRSTR)
            str=['Arg tests failed:' newline  strjoin(obj.ERRSTR,newline)];
            obj.append_error(str);
            obj.ERRSTR={};
        end
    end
    function append_error(obj,str)
        % val fld
        if isstruct(str)
            str=str.message;
        end
        if obj.bDebug
            error(str);
        end
        if obj.bNested
            obj.errors{end+1,1}=sprintf('%s: %s',obj.caller,str);
        else
            obj.errors{end+1,1}=str;
        end
        obj.exitflag=true;
    end
    function errorOption(obj,fld,bSelf)
        if nargin < 4
            bSelf=false;
        end
        if bSelf; s='Args '; else s=''; end
        str=sprintf('Invalid %soption ''%s''.',s,fld); %
        obj.append_error(str);
    end
    function errorMultiple(obj,fld,bSelf)
        if nargin < 4
            bSelf=false;
        end
        if bSelf; s='Args '; else s=''; end
        str=sprintf('Multiple instances of %soption ''%s.''',s,fld);
        obj.append_error(str);
    end
    function errorValue(obj,fld,val,bSelf)
        if nargin < 5
            bSelf=false;
        end
        if isnumeric(val) && size(val,1) == 1 && numel < 10
            val=Num.toStr(val);
        elseif isnumeric(val)
            val='numeric';
        elseif iscell(val)
            val='cell';
        elseif isstruct(val)
            val='struct';
        elseif isobject(val)
            val=class(val);
        end
        if bSelf; s='Args '; else s=''; end
        str=sprintf(['Invalid value ''%s'' for %soption ''%s.'''],val,s,fld); %
        obj.append_error(str);
    end
end
methods(Static, Access=private);
    function [out,obj]=parse_internal(parent,P,Opts,varargin)
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
        if ~obj.exitflag && obj.nout > 2
            obj.get_toggler();
        end
    end
    function x=cellparsefun(x)
        if iscell(x)
            x={x};
        end
    end
%%% MISC TESTS
end
end

