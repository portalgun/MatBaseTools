classdef ArgsPParser < handle
properties
   OUTDEF
   P
   PNest
   nestNames
   nestAliases
   nestAliasesAll
   % Cls Aliases prop

   %f2name
   %alias2f

   % P properties
   bDefault=false
   bTest=false
   bTestInd
   bAlias
   bFlag=false

   ExpandMatch
   ContractMatch
   ContractMatch12

   F
   %1
   allAliases
   names
   namesFlds
   aliases
   d_alias2name
   d_name2aliases

   cls1
   bNest1
   bNest1_1
   uNest1={}
   bCopy
   bStruct
   position
   bExpand
   bContract
   bContractB

   %2
   defaults

   % 3
   bNest3
   bNest3_any
   cls3
   nest3
   uNest3={}
   tests
   toggles

   % 4
   groups
   uGroups=[]
   bOptional
   Parent
end
properties(Constant,Hidden)
    %RE='^([0-9]+|!){1}([0-9]+|!){0,1}';
    RE='^([0-9]+|!|#){1}([0-9]+|!|#){0,1}';
end
methods
    function obj=ArgsPParser(P,Parent)
        obj.P=P;
        obj.Parent=Parent;
    end
    function parse(obj)

        [n,m]=size(obj.P);

        obj.bDefault=m >= 2;
        obj.bTestInd=~cellfun(@isempty,obj.P(:,3));
        obj.bTest=m >= 3 || all(bTestInd);
        obj.bFlag=m >= 4;

        %obj.F=arrayfun(@(x) ['f' num2str(x)],(1:n)','UniformOutput',false);

        % 4
        obj.parse4(); % 3 depends on 4

        % 1 & 3
        obj.parse3_flags(); % 3 & 1 interact
        obj.parse1(); % GET DICTS
        obj.parse3(); % GET TOGGLES

        % 2
        if obj.bDefault
            obj.defaults=obj.P(:,2);
        else
            obj.defaults=cell(n,1);
        end

        obj.initOut();
        obj.get_expand_contract_matches();
        %obj.get_PNest();
    end
    function initOut(obj)
        flds=cellfun(@(x) strsplit(x,'.'),obj.names,'UniformOutput',false);
        for i = 1:length(flds)
            obj.OUTDEF=setfield(obj.OUTDEF,flds{i}{:},obj.defaults{i}); % SLOW 3
        end
    end
    function parse4(obj)
        if ~obj.bFlag
            obj.groups=repmat({0},size(obj.P,1),1);
            obj.bOptional=false(size(obj.P,1),1);
            return
        end
        bGSimple=cellfun(@(x) numel(x)==1 && isnumeric(x), obj.P(:,4));
        if all(bGSimple)
            obj.groups=obj.P(:,4);
            obj.bOptional=cell2mat(obj.groups) > 0;
            return
        end
        [obj.groups,obj.bOptional]=cellfun(@(x) nest_fun(obj,x), obj.P(:,4),'UniformOutput',false);
        obj.bOptional=cell2mat(obj.bOptional);
        function [groups,bOptional]=nest_fun(obj,in)
            % Groups
            if isempty(in)
                groups=0;
            elseif isnumeric(in)
                groups=in;
            elseif ischar(in)
                groups=cellfun(@(x) str2double(x{2}), regexp(in,'((^|,) *)(-?[0-9]+)','tokens'));
                groups=[groups{:}];
            end
            ind=~ismember(groups,obj.uGroups);
            if any(ind)
                obj.uGroups=[obj.uGroups groups(ind)];
            end
            % OPTIONAL
            bOptional=~any(groups > 0);
        end
    end
    function parse3_flags(obj)
        n=size(obj.P,1);
        obj.tests=repmat({{''}},n,1);
        obj.bNest3=repmat({false},n,1);
        obj.cls3=repmat({{''}},n,1);

        bEmpty=cellfun(@isempty,obj.P(:,3));
        if ~obj.bTest || all(bEmpty)
            return
        end
        %P3=obj.P(:,3);
        bNest=~bEmpty;


        [obj.tests(bNest),obj.bNest3(bNest),meta,obj.cls3(bNest)]=cellfun(@(x) nest_fun(obj,x,obj.RE),obj.P(bNest,3),'UniformOutput',false);
        %[obj.tests,obj.bNest3,meta,obj.cls3]=cellfun(@(x) nest_fun(obj,x,obj.RE),obj.P(:,3),'UniformOutput',false);
        %if bTest
        %    33
        %    obj.bNest3
        %    obj.cls3
        %    obj.tests
        %    dk
        %end
        %obj.tests
        %obj.bNest3
        %obj.cls3
        %dk

        function [options,bNest3,meta,cls]=nest_fun(obj,in,RE)
            if isa(in,'dict') || isa(in,'struct')
                bNest3=true;
                meta=cell(1);
                cls={true};
                return
            elseif ~iscell(in)
                options={in};
            else
                options=in;
            end
            nInd=cellfun(@(x) isnumeric(x) || isa(x,'function_handle'),options);
            cls=cell(size(options));
            flags=cell(size(options));
            bNest3=false(size(options));
            bMeta=false(size(options));

            %bCls=false(size(options));


            if any(~nInd)
                %- SLOW
                bNest3(~nInd)=startsWith(options(~nInd),'!');
                bMeta(~nInd)=bNest3 & contains(options(~nInd),'@');
                options(~nInd)=regexprep(options(~nInd),RE,'');
                if any(bNest3)
                    cls(bNest3 & ~nInd)=cellfun(@(x) x(2:end),options(bNest3 & ~nInd),'UniformOutput',false);
                end
            end

            %[cls(~nInd),options(~nInd),flags(~nInd)]=cellfun(@(x) nest_nest_fun(x,RE),options(~nInd),'UniformOutput',false); %- SLOW

            %[bNest3(~nInd),bMeta(~nInd)]=cellfun(@nest_nest_fun2,cls(~nInd),flags(~nInd)); %- SLOW

            if any(bNest3)
                unest=unique(options(bNest3));
                ind=~ismember_cell(unest,obj.uNest3);
                if any(ind)
                    obj.uNest3=[obj.uNest3 unest];
                end
            end
            if ~bMeta
                meta=cell(size(bMeta));
                return
            end
            [meta,options]=cellfun(@Args.splitMetaArgs,options);
        end
        function [cls,options,flags]=nest_nest_fun(options,RE)
            re='[!]([A-Za-z0-9_]+)';

            cls=regexp(options,re,'tokens','once');
            cls=[cls{:}];
            flags=regexp(options,RE,'tokens','once');
            options=regexprep(options,RE,'');

        end
        function [bNest3,bMeta]=nest_nest_fun2(cls,flags)
            bNest3=~isempty(cls);
            bMeta=any(contains(flags,'@'));
        end
    end
    function parse1(obj)

        %obj.names=cellfun(@(x) regexprep(x,obj.RE,''),obj.P(:,1),'UniformOutput',false);
        bTest=false;
        if ~any(cellfun(@iscell ,obj.P(:,1)))
            mtch=regexp(strjoin(obj.P(:,1)),obj.RE,'once');
            if isempty(mtch)
                sz=[size(obj.P,1),1];
                obj.position=zeros(sz);
                obj.bNest1=num2cell(false(sz));
                obj.bNest1_1=false(sz);
                obj.bExpand=false(sz);
                obj.bStruct=false(sz);
                obj.bCopy=num2cell(false(sz));
                obj.bContract=num2cell(false(sz));
                obj.cls1=repmat({''},sz(1),sz(2));
                obj.names=obj.P(:,1);
                obj.aliases=cellfun(@(x) {x} ,obj.P(:,1),'UniformOutput',false);
                obj.bAlias=false;
                obj.allAliases=obj.names;
                return
                %bTest=true;
            end
        end
        obj.d_alias2name=containers.Map;
        obj.d_name2aliases=containers.Map;
        [obj.names,obj.aliases,obj.bNest1,obj.cls1,obj.bCopy,bStruct,obj.position,bExpand,obj.bContract]=cellfun(@(x) nest_fun(x,obj.RE),obj.P(:,1),'UniformOutput',false);

        obj.position=cell2mat(obj.position);
        obj.bExpand=cell2mat(bExpand);
        obj.bStruct=cell2mat(bStruct);
        obj.bNest1_1=cellfun(@(x) x(1),obj.bNest1);

        %e=obj.aliases(obj.bExpand)
        %e{:}
        %c=obj.aliases(obj.bContract)
        %c{:}

        %if bTest
        %    33
        %        obj.position
        %        obj.bNest1
        %        obj.bExpand
        %        obj.bCopy
        %        obj.bContract
        %        obj.cls1
        %        obj.names
        %        obj.aliases

        %dk
        %end

        obj.get_dicts(false);
        function [name,naliases,bNest1,cls1,bCopy,bStruct,pos,bExpand,bContract] = nest_fun(in,RE)
            if ~iscell(in)
                aliases={in};
                name=in;
            else
                aliases=in;
                name=in{1};
            end
            flags=regexp(aliases,RE,'tokens','once'); %- SLOW 2
            %b=regexp(aliases,RE,'start','once'); %- SLOW 2
            %bEmp=isempty([b{:}]);
            bEmp=cellfun(@(x) any(isempty(x)),flags); %- SLOW 1
            naliases=regexprep(aliases,RE,''); %- SLOW 3
            name=regexprep(name,RE,'');        %- SLOW 4


            %[bNest1,bCopy,bStruct,bEmp]=cellfun(@nest_nest_fun,flags,aliases);
            bNest1=contains(aliases,'!');
            bCopy=contains(aliases,'#');
            bStruct=contains(naliases,'.');

            %bStruct=cellfun(@(x,y) any(contains(x,'.') | contains(y,'!')),aliases,flags);
            bExpand=  numel(bStruct) > 1 &&  bStruct(1) && ~any(bStruct(2:end));
            if bExpand
                bContract=find(bStruct);
            end
            bContract=numel(bStruct) > 1 && ~bStruct(1) &&  any(bStruct(2:end));
            if bContract
                bContract=find(bStruct);
            end
            if bNest1(1)
                cls1=name;
            else
                cls1='';
            end

            nInd=~bEmp & ~bNest1 & ~bCopy;
            if ~any(nInd)
                pos=0;
            else
                pos=flags{1}(nInd);
            end
            %flags(cellfun(@isempty,flags))=[];
            bStruct=any(bStruct);

        end
        function [bNest1,bCopy,bStruct,bEmp]=nest_nest_fun(flags,aliases)
            bNest1=any(contains(flags,'!'));
            bCopy=any(contains(flags,'#'));
            bStruct=any(contains(aliases,'.'));
            bEmp=any(isempty(flags));
        end
    end
    function aliases=name2aliases(obj,name);
        if obj.bAlias
            aliases=obj.d_name2aliases(name);
        else
            aliases={name};
        end
    end
    function name=alias2name(obj,alias);
        if obj.bAlias
            name=obj.d_alias2name(alias);
        else
            name=alias;
        end
    end
    function get_dicts(obj,bEasy)

        usr=obj.Parent.UsrNames; % NOTE REQUIRES USER ARGS

        bNest3=cellfun(@(x) numel(x)==1 && x,obj.bNest3);
        obj.bAlias=any(bNest3);
        if ~obj.bAlias
            obj.allAliases=obj.names;
            return
        end

        obj.names=cellfun(@(n,b,o) name_fun(obj,usr,n,b,o), obj.aliases, obj.bNest3, num2cell(obj.bNest1_1),'UniformOutput',false);

        % NOTE REGET NAMES AND ALIASES
        obj.aliases=cellfun(@(x) obj.d_name2aliases(x),obj.names,'UniformOutput',false);
        obj.allAliases=[obj.aliases{:}]';

        %obj.aliases{:}
        function name=name_fun(obj,usrkeys,names,bNest3,bNest1)
            if bNest3(1) & bNest1 & length(names)==2 && isequal(ismember_cell(names,usrkeys),[false true]) %- SLOW 3
                % NOTE THIS CHANGES ORDER OF P1 BASED UPON TYPE USER IS PROVIDING
                if length(names)==2
                    names=[names(2) names(1)];
                else
                    names=[names(2) names(1) names(3:end)];
                end
            end
            if iscell(names)
                % HANDLE ALIASES
                name=names{1};
                obj.d_name2aliases(name)=names; %- SLOW 1
                %obj.f2name(f)=names{i};
                for j = 1:length(names)
                    %obj.alias2f(name)=f;
                    %obj.d_alias2name(names{i})=names{i};
                    obj.d_alias2name(names{j})=name; %- SLOW 2
                end
            else
                name=names;
                obj.d_name2aliases(names)={names};
                %obj.f2name(f)=names;
                obj.alias2f(names)=f;
                obj.d_alias2name(names)=names;
            end
        end
    end
    function parse3(obj)
        %% GET TESTS AND TOGGLES
        if ~obj.bTest
            obj.tests=@(varargin) true;
            obj.toggles=[obj.names,obj.tests];
            return
        end
        [obj.tests,obj.toggles]=cellfun(@(a,t,o,c,bn3,bn1,bo) nest_fun(a,t,o,c,bn3,bn1,bo), obj.aliases,obj.tests,obj.cls1,obj.cls3,obj.bNest3,obj.bNest1,num2cell(obj.bOptional),'UniformOutput',false);
        obj.toggles=vertcat(obj.toggles{:});

        function [test,toggle]=nest_fun(aliases,T,prp,cls,bNest3,bNest1,bOptional)

            %if bOptional || isempty(T) || (iscell(T) && numel(T) == 1 && isempty(T{1}))
            if isempty(T) || (iscell(T) && numel(T) == 1 && isempty(T{1}))
                test=@(varargin) true;
                tog=test;

                toggle={aliases{1},tog};
                return
            elseif bNest3
                % HANDLE OPTIONS AND STRUCTS
                cls(cellfun(@islogical,cls))=[];
                if isempty(cls)
                    test=@(x) isobject(x) || ismember_cell(class(x),{'dict','struct'});
                elseif numel(bNest3)==1 && numel(cls) == 1
                    % 1 object
                    test=@(x) isa(x,cls{1});
                elseif  numel(bNest3) == numel(cls)
                    % multiple objects
                    test=@(x) ismember_cell(class(x),cls);
                elseif numel(bNest3) > numel(cls)
                    % structs and object
                    test=@(x) ismember_cell(class(x),[cls,{'dict','struct'}]);
                end
                tog=test;

                if bNest1(1)
                    toggle={['@' prp] cls{1}};
                    % XXX TOGGLES HANDLE NESTED CLASSES DIFFERENTLY?
                    % check to see if child has toggler
                else
                    toggle={aliases{1},tog};
                end
                return
            end

            if iscell(T) && numel(T) == 1
                T=T{1};
            end

            if isa(T,'function_handle')
                test=T;
                tog=T;
            elseif isnumeric(T) && (numel(T)==2 || numel(T)==3)
                % min,max,inc
                test=@(x) x >= T(1) && x <= T(end);
                tog=test;
            elseif iscell(T) || (isnumeric(T) && numel(T) > 3)
                % list
                if isnumeric(T)
                    tog=num2cell(T);
                else
                    tog=T;
                end

                test=@(x) ismember(x,tog);
            elseif regexp(T,'(is[bB]inary|islogical)(_e)?$')
                % binary -> list
                test=Args.parseTest(T);
                tog={false,true};
            else
                test=Args.parseTest(T);
                tog=test;
            end
            toggle={aliases{1},tog};
        end
    end
    function [nestName,N]=name2nestName(obj,name, N)
        nestName=[];
        if nargin < 2
            N=obj.name2nestMatch(name);
        end
        if N == 0
            return
        end
        [~,n]=ismember_cell(obj.nestAliases{N},name);
        nestName=obj.nestAliases{N}{n,1};
    end
    function N=name2nestMatch(obj,name)
        if ismember(name,obj.allAliases) | ~ismember(name,obj.nestAliasesAll) % anything unmatched can be expanded
            N=0;
            return
        end
        N=find(cellfun(@(x) any(ismember(name,x)), obj.nestAliases));
    end
    function get_PNest(obj)
        obj.PNest=cell(numel(obj.bNest3),1);
        obj.nestNames=cell(numel(obj.bNest3),1);
        obj.nestAliases=cell(numel(obj.bNest3),1);

        bAny=cellfun(@any,obj.bNest3);
        obj.bNest3_any=bAny;
        if ~any(obj.bNest3_any)
            return
        end
        [obj.PNest(bAny),obj.nestNames(bAny),obj.nestAliases(bAny),obj.nestAliasesAll]=cellfun(@(x,y) nest_fun(obj,x,y) ,obj.cls3(bAny),obj.aliases(bAny),'UniformOutput',false);

        obj.nestAliasesAll=vertcat(obj.nestAliasesAll{:});

        % SET
        %[U,~,ic]=unique(nestNames);
        %obj.nestNames=cell(size(obj.names));
        %obj.nestAliases=cell(size(obj.aliases));
        %for i = 1:length(U)
        %    r=find(cellfun(@(x) any(ismember(x,U{i})),obj.aliases));
        %    r
        %    obj.nestNames{r}=nestAliases(ic==i,1);
        %    obj.nestAliases{r}=nestAliases(ic==i,:);
        %end

        %obj.nestAliasesAll=nestAliasesAll;

        function [P,name,aliases,allAliases]=nest_fun(obj,cls,aliases)
            cls=cls{~cellfun(@isempty,cls)};
            if isempty(which(cls))
                obj.Parent.append_error(sprintf('Unknown class ''%s''',cls));
                return
            end

            % TODO LATER?
            meth='getP';
            args={};

            str=[cls '.' meth '(args{:});'];
            try
                P=eval(str);
            catch ME
                obj.Parent.append_error(ME);
            end
            if ~isempty(P)
                %cls=repmat({cls},size(P,1),1);
                aliases=repmat(aliases,size(P,1),1);
            end

            % EXPAND ALL ALIASES
            [n,~]=size(aliases);
            [name,aliases]=cellfun(@distribute_fun ,mat2cell(aliases,ones(n,1)) ,P(:,1),'UniformOutput',false);

            allAliases=vertcat(aliases{:});
            function [name,fullAliases]=distribute_fun(a,p)
                p=strrep(p,'!',''); % NOTE
                if ischar(p)
                    name=p;
                    p={p};
                else
                    name=p{1};
                end
                cols=strcat(Set.distribute( strcat(a,'.'), p ));
                fullAliases=[p'; strcat(cols(:,1),cols(:,2))];
            end
        end
    end
    function [bExpand,bContract]=get_expand_contract_matches(obj)
        bExpand=obj.bExpand;
        obj.ExpandMatch=cell(size(obj.names));
        %if any(bExpand)
        %    obj.ExpandMatch(obj.bExpand)=cellfun(@(x) find_match_fun(obj,x), obj.aliases(obj.bExpand),'UniformOutput',false);
        %end

        obj.ContractMatch=cell(size(obj.names));
        obj.ContractMatch12=zeros(size(obj.names,1),2);
        %bInd=cellfun(@(x) x>0,obj.bContract);
        bInd=cellfun(@(x) any(x>0),obj.bContract);
        obj.bContractB=bInd;
        if any(bInd)
            inds=obj.bContract(bInd);
            [obj.ContractMatch(bInd),out1,out2]=cellfun(@(x,y) find_match_fun(obj,x,y), obj.aliases(bInd),inds,'UniformOutput',false);
            obj.ContractMatch12(bInd,:)=cell2mat([out1 out2]);
        end
        function [out,out1,out2]=find_match_fun(obj,aliases,inds)
            if nargin < 3
                inds=2:length(aliases);
            end
            %aliases=regexprep(aliases(inds),'\..*$','');
            aliases=aliases(inds);
            mInds=cellfun(@(x) find(ismember_cell(x, aliases  )), obj.aliases,'UniformOutput',false);
            bind=find(~cellfun(@isempty,mInds));
            out=[bind vertcat(mInds{bind})];
            out1=out(1);
            out2=out(2);
            %out=mInds;
            %out=cellfun(@(x,y) x{y} ,obj.aliases(bInd),mInds(bInd),'UniformOutput',false);
        end
    end

end
end
