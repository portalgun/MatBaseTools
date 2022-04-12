classdef ArgsPParser < handle
properties
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
   bFlag=false

   ExpandMatch
   ContractMatch

   F
   %1
   allAliases
   names
   aliases
   alias2name
   name2aliases

   bNest1
   bNest1_1
   uNest1={}
   bCopy
   position
   bExpand
   bContract

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
        obj.bTest=m >= 3;
        obj.bFlag=m >= 4;

        obj.F=arrayfun(@(x) ['f' num2str(x)],(1:n)','UniformOutput',false);

        % 4
        obj.parse4(); % 3 depends on 4

        % 1 & 3
        obj.parse3_flags(); % 3 & 1 interact
        obj.parse1();
        obj.parse3();

        % 2
        if obj.bDefault
            obj.defaults=obj.P(:,2);
        else
            obj.defaults=cell(n,1);
        end

        %obj.get_PNest();
    end
    function parse4(obj)
        if ~obj.bFlag
            obj.groups=repmat({0},size(obj.P,1),1);
            obj.bOptional=false(size(obj.P,1),1);
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
        if ~obj.bTest
            n=size(obj.P);
            obj.tests=repmat({@(varargin) true},n,1);
            obj.bNest3=repmat({false},n,1);
            return
        end
        [obj.tests,obj.bNest3,meta,obj.cls3]=cellfun(@(x) nest_fun(obj,x,obj.RE),obj.P(:,3),'UniformOutput',false);
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
            nInd=cellfun(@isnumeric,options);
            re='[!]([A-Za-z0-9_]+)';
            cls=cell(size(options));
            cls(~nInd)=cellfun(@(x) [x{:}] ,regexp(options(~nInd),re,'tokens','once'),'UniformOutput',false);
            %cls=regexp(options,re,'tokens');

            flags=cell(size(options));
            flags(~nInd)=regexp(options(~nInd),RE,'tokens','once');
            options(~nInd)=cellfun(@(x) regexprep(x,RE,''),options(~nInd),'UniformOutput',false);

            bNest3=false(size(options));
            bNest3(~nInd)=~cellfun(@isempty,cls(~nInd));
            %bNest3(~nInd)=cellfun(@(x) any(contains(x,'!')),flags(~nInd));
            if any(bNest3)
                unest=unique(options(bNest3));
                ind=~ismember(unest,obj.uNest3);
                if any(ind)
                    obj.uNest3=[obj.uNest3 unest];
                end
            end
            %bCopy=cellfun(@(x) any(contains(x,'#')),flags);
            bMeta=false(size(options));
            bMeta(~nInd)=cellfun(@(x) any(contains(x,'@')),flags(~nInd));
            if ~bMeta
                meta=cell(size(bMeta));
                return
            end
            [meta,options]=cellfun(@Args.splitMetaArgs,options);
        end
    end
    function parse1(obj)
        %obj.names=cellfun(@(x) regexprep(x,obj.RE,''),obj.P(:,1),'UniformOutput',false);
        [obj.names,obj.aliases,obj.bNest1,obj.bCopy,obj.position,bExpand,obj.bContract]=cellfun(@(x) nest_fun(x,obj.RE),obj.P(:,1),'UniformOutput',false);

        obj.position=cell2mat(obj.position);
        obj.bExpand=cell2mat(bExpand);
        obj.bNest1_1=cellfun(@(x) x(1),obj.bNest1);

        %e=obj.aliases(obj.bExpand)
        %e{:}
        %c=obj.aliases(obj.bContract)
        %c{:}


        obj.get_dicts();
        function [name,aliases,bNest1,bCopy,pos,bExpand,bContract] = nest_fun(in,RE)
            if ~iscell(in)
                aliases={in};
                name=in;
            else
                aliases=in;
                name=in{1};
            end
            flags=regexp(aliases,RE,'tokens','once');
            name=regexprep(name,RE,'');
            aliases=regexprep(aliases,RE,'');


            bStruct=cellfun(@(x,y) any(contains(x,'.') ),aliases);
            %bStruct=cellfun(@(x,y) any(contains(x,'.') | contains(y,'!')),aliases,flags);
            bExpand=  numel(bStruct) > 1 &&  bStruct(1) && ~any(bStruct(2:end));
            if bExpand
                bContract=find(bStruct);
            end
            bContract=numel(bStruct) > 1 && ~bStruct(1) &&  any(bStruct(2:end));
            if bContract
                bContract=find(bStruct);
            end
            bNest1=cellfun(@(x) any(contains(x,'!')),flags);
            bCopy=cellfun(@(x) any(contains(x,'#')),flags);
            bEmp=cellfun(@(x) any(isempty(x))     ,flags);

            nInd=~bEmp & ~bNest1 & ~bCopy;
            if ~any(nInd)
                pos=0;
            else
                pos=flags{1}(nInd);
            end
            %flags(cellfun(@isempty,flags))=[];

        end
    end
    function get_dicts(obj)
        %obj.alias2f=containers.Map;
        %obj.f2name=containers.Map;
        %
        obj.alias2name=containers.Map;
        obj.name2aliases=containers.Map;

        usr=keys(obj.Parent.UsrArgs); % NOTE REQUIRES USER ARGS

        obj.names=cellfun(@(n,f,b,o) name_fun(obj,usr,n,f,b,o), obj.aliases, obj.F, obj.bNest3, num2cell(obj.bNest1_1),'UniformOutput',false);

        % NOTE REGET NAMES AND ALIASES
        obj.aliases=cellfun(@(x) obj.name2aliases(x),obj.names,'UniformOutput',false);
        obj.allAliases=[obj.aliases{:}]';

        function name=name_fun(obj,usrkeys,names,f,bNest3,bNest1)
            if bNest3(1) & bNest1 & length(names)==2 && isequal(ismember(names,usrkeys),[false true])
                % NOTE THIS CHANGES ORDER OF P1 BASED UPON TYPE USER IS PROVIDING
                i=2;
            else
                i=1;
            end
            if iscell(names)
                % HANDLE ALIASES
                name=names{i};
                obj.name2aliases(name)=names;
                %obj.f2name(f)=names{i};
                for j = 1:length(names)
                    %obj.alias2f(name)=f;
                    %obj.alias2name(names{i})=names{i};
                    obj.alias2name(names{j})=name;
                end
            else
                name=names;
                obj.name2aliases(names)={names};
                %obj.f2name(f)=names;
                obj.alias2f(names)=f;
                obj.alias2name(names)=names;
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
        [obj.tests,obj.toggles]=cellfun(@(a,t,c,bn3,bn1,bo) nest_fun(a,t,c,bn3,bn1,bo), obj.aliases,obj.tests,obj.cls3,obj.bNest3,obj.bNest1,num2cell(obj.bOptional),'UniformOutput',false);
        obj.toggles=vertcat(obj.toggles{:});
        function [test,toggle]=nest_fun(aliases,T,cls,bNest3,bNest1,bOptional)

            if bOptional || isempty(T) || (iscell(T) && numel(T) == 1 && isempty(T{1}))
                test=@(varargin) true;
                tog=test;
                toggle={aliases{1},tog};
                return
            elseif bNest3
                % HANDLE OPTIONS AND STRUCTS
                cls(cellfun(@islogical,cls))=[];
                if isempty(cls)
                    test=@(x) isobject(x) || ismember(class(x),{'dict','struct'});
                elseif numel(bNest3)==1 && numel(cls) == 1
                    % 1 object
                    test=@(x) isa(x,cls{1});
                elseif  numel(bNest3) == numel(cls)
                    % multiple objects
                    test=@(x) ismember(class(x),cls);
                elseif numel(bNest3) > numel(cls)
                    % structs and object
                    test=@(x) ismember(class(x),[cls,{'dict','struct'}]);
                end
                tog=test;
                toggle={aliases{1},tog};
                return
            end

            if iscell(T) && numel(T) == 1
                T=T{1};
            end
            if isnumeric(T) && (numel(T)==2 || numel(T)==3)
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
        [n,~]=find(ismember(obj.nestAliases{N},name));
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
                obj.Parent.append_error(srpintf('Unknown class ''%s''',cls));
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
        bInd=cellfun(@(x) x>0,obj.bContract);
        bContract=bInd;
        if any(bInd)
            inds=obj.bContract(bInd);
            obj.ContractMatch(bInd)=cellfun(@(x,y) find_match_fun(obj,x,y), obj.aliases(bInd),inds,'UniformOutput',false);
        end
        function out=find_match_fun(obj,aliases,inds)
            if nargin < 3
                inds=2:length(aliases);
            end
            %aliases=regexprep(aliases(inds),'\..*$','');
            aliases=aliases(inds);
            mInds=cellfun(@(x) find(ismember(x, aliases  )), obj.aliases,'UniformOutput',false);
            bInd=find(~cellfun(@isempty,mInds));
            out=[bInd vertcat(mInds{bInd})];
            %out=mInds;
            %out=cellfun(@(x,y) x{y} ,obj.aliases(bInd),mInds(bInd),'UniformOutput',false);
        end
    end

end
end
