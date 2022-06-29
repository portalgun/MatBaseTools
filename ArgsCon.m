classdef ArgsCon < handle
properties
   nUnm
   bUUnMatched
   bUParsed
   UsrNames
   UsrVals

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
   bInit=1;
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
    function obj=ArgsCon(OBJ,P,Opts,argsin)
        if isempty(Opts)
           Opts=struct();
        end
        obj.Opts=Opts;
        obj.parse_own();

        %% INIT
        if ~obj.exitflag
            if obj.bInit
                obj.P=ArgsPParser(P,obj);
            end
        end

        %% MAIN
        if ~obj.exitflag
            obj.main(OBJ,argsin);
        end

        %% ERRORS
    end
    function preUsrParse(obj,argsin)

        if isstruct(argsin)
            argsin={argsin};
        end
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

                    %obj.UsrArgs=containers.Map(keys,vals);
                    obj.UsrNames=keys;
                    obj.UsrVals=vals;
                else
                    %obj.UsrArgs=containers.Map();
                end
            case 'dict'
                %obj.UsrArgs=argsin{1};
                obj.UsrVals=argsin{1}.vals;
                obj.UsrNames=argsin{1}.keys;
                obj.bUDict=true;
            otherwise
                if ~isempty(argsin{1})
                    error('TODO')
                end
                %obj.UsrArgs=containers.Map;
            end

        else
            obj.bNotArgIn=false;

            [keys,vals,~,obj.nPosArgs]=Args.pairsToKeysVals(argsin{:});
            obj.UsrVals=vals';
            obj.UsrNames=keys';
            %vals
            %vals=cellfun(@Args.cellparsefun,vals,'UniformOutput',false);

            %obj.UsrArgs=containers.Map(keys,vals);
        end
        if isempty(obj.UsrNames)
            obj.UsrNames={};
            obj.UsrVals={};
        end
    end

    function out=parse(obj,OBJ,argsin)
        obj.main(OBJ,argsin);
        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
        obj.OBJ=[];
        if ~isempty(errors); throwAsCaller(errors); end
    end
    function main(obj,OBJ,argsin)
        obj.OUT=[];
        obj.OUT_S=[];
        obj.OUTUM=[];

        obj.nUnm=[];
        obj.bUUnMatched=[];
        obj.bUParsed=[];
        obj.UsrNames=[];
        %obj.UsrArgs=[];
        obj.UsrPosArgs=[];
        obj.UNestMatch=[];
        obj.OBJ=OBJ;
        obj.preUsrParse(argsin);

        if obj.exitflag; return; end

        %obj.P.parse(); %HERE

        if obj.bInit
            obj.P.parse();
            if obj.exitflag; return; end
        end
        obj.bInit=false;

        %obj.P.bTestInd=~cellfun(@isempty,obj.P.P(:,3));

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

        %assignin('base','bUUn',obj.bUUnMatched)
        %assignin('base','PInd',obj.PIndMatched)

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

        %if obj.nout >= 3
        %    obj.get_toggler();
        %end
    end
    function expand_contract(obj)
    % CONTRACT EXAMPLE
    % {'!trgt','trgtOpts'},                     [], '!PointDispWin3D',  1;
    % {'trgtDsp','trgtDSP','trgtOpts.trgtDsp'}, [], '',                42;
    % if tgtDsp set in trgtOpts, needs to be taken out and made its own param

        bStructs=structfun(@isstruct,obj.OUT);

        %obj.P.get_expand_contract_matches();
        %[bExpand,bContract]=obj.P.get_expand_contract_matches();

        %if any(obj.P.bExapnd)
        %    match=obj.P.ExpandMatch(bExpand);
            % struct is preffered
            %'e'
            %pname
        %end

        if any(bStructs) && any(obj.P.bContractB)
            bUnMatched=~ismember((1:numel(obj.P.names))',obj.PIndMatched);
            Bind=bUnMatched & obj.P.bContractB;
            if ~any(Bind)
                return
            end

            %pinds=obj.P.ContractMatch12(Bind,1);
            %ainds=num2cell(obj.P.ContractMatch12(Bind,2));
            %names=obj.P.names(pinds);
            %aliases=obj.P.aliases(pinds);
            %strNames=cellfun(@(x,y) x(y),aliases,ainds,'UniformOutput',false);

            cellfun(@(x) contract_fun(obj,x),obj.P.ContractMatch(Bind));
            %cellfun(@(x,y,z) contract_fun2(obj,x,y,z), strNames,num2cell(pinds),names);
            %names=obj.P.names(bContract);
            obj.combine_errors();
        end
        function contract_fun2(obj,strName,pind,name)
            spl = regexp(strName, '\.', 'split');
            try
                val=getfield_fast(obj.OUT,spl{:});
            catch
                return
            end

            if obj.P.bTestInd(pind)
                test=obj.P.tests(pind);
                exiflag=obj.run_test(test,strName,val);
                if exiflag
                    return
                end
            end

            obj.OUT.(name)=val;

            % RM
            str=strjoin(spl(1:end-1),'.');
            cmd=sprintf('obj.OUT.%s=rmfield(obj.OUT.%s,spl{end});',str,str);
            eval(cmd);
        end
        function contract_fun(obj,minds)

            % thing to set
            pind=minds(1);
            name=obj.P.names{pind};

            % struct match to aliases - field to get value from
            aliases=obj.P.aliases{pind}; % tmp
            strName=aliases{minds(2)};
            spl = regexp(strName, '\.', 'split');

            % GET VALUE IF IT EXISTS
            try
                val=getfield_fast(obj.OUT,spl{:});
            catch
                return
            end

            if obj.P.bTestInd(pind)
                test=obj.P.tests(pind);
                exiflag=obj.run_test(test,strName,val);
                if exiflag
                    return
                end
            end

            % SET
            %obj.OUT=setfield(obj.OUT,name,val);
            obj.OUT.(name)=val;

            % RM
            str=strjoin(spl(1:end-1),'.');
            cmd=sprintf('obj.OUT.%s=rmfield(obj.OUT.%s,spl{end});',str,str);
            eval(cmd);
        end
    end
    function parse_own(obj)
        oP=Args.getP();
        flds=sort(fieldnames(obj.Opts));
        seen='';
        [bP,Pc]=ismember_cell(flds,oP(:,1));
        for i = 1:length(flds)
            fld=flds{i};
            val=obj.Opts.(fld);
            if bP(i)
                %p=oP(ismember_cell(oP(:,1),fld),:);
                p=oP(Pc(i),:);
                name=p{1};
                if strcmp(name,seen)
                    obj.errorMultiple(fld,true);
                    continue
                end
                seen=name;

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
        %obj.UsrNames=keys(obj.UsrArgs);
        if obj.nPosArgs > 0
            obj.UsrPosArgs
        end

    end
    function get_usr_unmatched(obj)
        bind=ismember_cell(obj.UsrNames,obj.P.allAliases); % SLOW
        if isempty(obj.UsrNames)
            return
        end


        if islogical(obj.PIndMatched)
            obj.PIndMatched=double(obj.PIndMatched);
        end
        bPIM=obj.PIndMatched >= 1;

        obj.PIndMatched(~bPIM & obj.UNestMatch)=double(obj.UNestMatch(~bPIM & obj.UNestMatch));

        bPimSet=~bPIM & ~obj.UNestMatch & bind;
        if obj.P.bAlias
            [~,obj.PIndMatched(bPimSet)]=cellfun(@(x) ismember_cell(obj.P.alias2name(x),obj.P.names),obj.UsrNames(bPimSet)); % SLOW
        else
            [~,obj.PIndMatched(bPimSet)]=cellfun(@(x) ismember_cell(x,obj.P.names),obj.UsrNames(bPimSet));
            %[~,obj.PIndMatched(bPimSet)]=ismember_cell(obj.UsrNames(bPimSet),obj.P.names); SLOWER SOMEHOW
        end

        obj.bUUnMatched=~bPIM & ~obj.UNestMatch & ~bind;
        obj.nUnm=sum(obj.bUUnMatched);
    end
%% MAIN
    function handle_unmatched(obj)
        %obj.OUTUM=containers.Map();
        %obj.get_unmatched();
        if obj.nUnm == 0
            return
        end
        UM=obj.UsrNames(obj.bUUnMatched);
        if ~obj.IgnoreUnmatched && ~obj.KeepUnmatched
            if iscell(UM)
                um=strjoin(UM,newline);
            else
                um=UM;
            end
            obj.append_error(sprintf('Unmatched paramters:\n%s',um));
        else
            obj.OUTUM=struct();
            for i = 1:length(UM)
                obj.OUTUM.(UM{i})=obj.get_user_val(UM{i});
            end
        end
    end
    function parse_usr_matched(obj)
        % INIT OUT WITH DEFAULTS
        obj.OUT=obj.P.OUTDEF;

        GdInd=~obj.bUUnMatched & ~obj.bUParsed;
        unames=obj.UsrNames(GdInd);
        vals=obj.UsrVals(GdInd);

        pinds=obj.PIndMatched(GdInd);
        pnames=obj.P.names(pinds);
        tests=obj.P.tests(pinds);

        bTest=obj.P.bTestInd(pinds);
        bUM=logical(Vec.col(obj.UNestMatch(GdInd)));
        %bUM=obj.UNestMatch(GdInd);
        %
        %bStruct=(~bUM & contains(pnames,'.'));

        bP=~(obj.P.bOptional(pinds) & cellfun(@isempty,vals));

        types=ones(size(bUM))*3;
        types(~bUM & obj.P.bStruct(pinds) & ~obj.P.bContractB(pinds))=2;
        types(bUM)=1;
        types(bTest)=types(bTest)*-1;

        cellfun(@obj.set_fun,vals(bP),tests(bP),pnames(bP),unames(bP),num2cell(types(bP)));

    end
    function set_fun(obj,val,test,pname,uname,typ)
        if sign(typ)<0
            exiflag=obj.run_test(test,uname,val);
            if exiflag
                return
            end
        end
        typ=abs(typ);

        if typ==1
            newName=obj.P.name2nestName(uname,UM);
            flds = regexp(newName, '\.', 'split');

            obj.OUT = builtin('subsasgn', obj.OUT, struct('type',repmat({'.'},1,numel(flds)),'subs',flds), val);
            obj.OUT=setfield(obj.OUT,flds{:},val);
        elseif typ==2
            flds = regexp(pname, '\.', 'split');

            obj.OUT = builtin('subsasgn', obj.OUT, struct('type',repmat({'.'},1,numel(flds)),'subs',flds), val);
            obj.OUT=setfield(obj.OUT,flds{:},val);
        elseif typ==3
            obj.OUT.(pname)=val;
        end
    end
    function exitflag=run_test(obj,test,uname,val)
        exitflag=false;
        if numel(test) == 1 && iscell(test) && numel(test{1})==1
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
    function parse_groups(obj)
        if isempty(obj.P.uGroups) || all(ismember_cell(obj.P.uGroups(1),[0 -1]))
            return
        end
        names=obj.P.names;
        obj.UsrArgs=unique([abs(obj.uGroups) 0 1 ])';
        N=numel(obj.UsrArgs);
        n=numel(numel(obj.uGroups));
        A=[obj.UsrArgs zeros(length(obj.UsrArgs),4)];
        for i = 1:length(obj.uGroups)
            u=obj.uGroups(i);
            bGroup=cellfun(@(x) ismember_cell(u,x),obj.groups);
            n=cellfun(@(x) ~isempty(obj.get_result(x)),names(bGroup));
            Ai=find(ismember_cell(A(:,1),abs(u)));
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

%% UTIL
    function val=get_user_val(obj,name)
        val=[obj.UsrVals{ismember_cell(obj.UsrNames,name)}];
    end
    function name=alias2name(obj,alias)
        aliases=obj.P.name2aliases(alias);
        name=aliases{1};
    end
%% RESULTS
    function out=get_result(obj,fld)
        out=obj.get_result_f(obj.P.alias2f(fld));
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
    function out_as_object(obj)
        flds=obj.P.names;
        bContainer=isa(obj.OBJ,'Container');
        for i = 1:length(flds)
            %obj.OBJ= builtin('subsasgn', obj.OBJ, struct('type','.','subs',flds{i}), obj.OUT.(flds{i}));
            if ~bContainer && isempty(obj.OUT.(flds{i}))
                continue %TODO MAKE THIS AN OPTION NOT IMPLIED
            end
            obj.OBJ.(flds{i})=obj.OUT.(flds{i}); % WHY SLOW?
        end

        obj.OUT=obj.OBJ;

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
                elseif contains(names{i},'.')
                    flds=strsplit(names{i},'.');
                    vals{i}=getfield_fast(obj.OUT,flds{:});
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

