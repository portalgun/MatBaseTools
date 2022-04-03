classdef Args < handle
%% TODO
%%   - DON'T ALLOW DUPLICATES
%% P columns
%%  1 - names
%%        main name = 1
%%        aliases 2
%%        'opts.fld.val' -> struct
%%  3 - tests/nested
%%        struct => nestedP
%%        char starting with ! => nested P
%%        char => function
%%        [min,[inc,]max]
%%        {values}
%%  4 - flags
%%        numbers = groups
properties
   nPosArgs
   dictf
   dictr
   ARGS
   OBJ
   objName
   Opts
   P
   KeepUnmatched=false
   IgnoreUnmatched=false
   CaseSensitive=false
   StructExpand=true
   errors={}
   bNotArgIn=true
   nested
   groups
   uGroups

   IP
   Toggler

   bDefault
   bTest=false
   bFlag=false

   OUT=struct
   OUTUM
end
properties(Hidden)
   toggles
end
methods(Static)
%%% MAIN INTERFACES
    function [out,obj]=parse(parent,P,varargin)
        obj=Args(parent,P,struct(),varargin);
        out=obj.OUT;
        if nargout >= 2
            obj.get_toggler();
        end
    end
    function [out,unmatched,obj]=parseLoose(parent,P,varargin)
        Opts=struct('KeepUnmatched',true);
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
        unmatched=obj.OUTUM;
        if nargout >= 3
            obj.get_toggler();
        end
    end
    function [out,obj]=parseIgnore(parent,P,varargin)
        Opts=struct('KeepUnmatched',false,'IgnoreUnmatched',true);
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
        if nargout >= 2
            obj.get_toggler();
        end
    end
    function [out,obj]=parseKeep(parent,P,varargin)
        Opts=struct('KeepUnmatched',true,'IgnoreUnmatched',true);
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
        if nargout >= 2
            obj.get_toggler();
        end
    end
    function out=mergePref(obj,varargin)
        ARGS=varargin;
        types=cellfun(@class,ARGS);
        type=Arr.mode(types);
        type=type{1};
        convertInd=~ismember(types,type);
        if sum(convertInd) > 1
            error('TOOD')
        end

        switch type
        case 'dict'
            out=ARGS{1};
            for i = 2:length(varargin)
                out.mergePref(ARGS{i},true,true);
            end
        case 'struct'
            out=ARGS{1};
            for i = 2:length(varargin)
                Struct.mergePref(ARGS{i},true,true);
            end
        end
    end
    function out=getUnmatched(P,varargin)
        pNames=P(:,1);
        %% TODO HANDLE UNNAMED ARGS
        flds=fieldnames(struct(varargin{:}));
        out=flds(~ismember(flds,pNames));
    end
    function throwUnmatchedError(parentName,UM)
        % TODO
    end
    function out=toPairs(in)
        if isstruct(in)
            flds=fieldnames(in);
            out=cell(1,numel(flds));
            for i = 1:length(flds)
                out{i*2-1}=flds{i};
                out{i*2}=in(flds{i});
            end
        elseif isa(in,'dict')
            k=in.keys;
            v=in.vals;
            s=[k v]';
            out=Vec.row(s);
        else
            error(['unhandled type ' class(in)]);
        end
    end
%% UTIL
    function [val,varargin]=getPair(name,varargin)
        ind=find(cellfun(@(x) isequal(x,name),varargin));
        if ~isempty(ind)
            val=varargin{ind+1};
            varargin(ind+1)=[];
            varargin(ind)=[];
        else
            val=0;
        end
    end
    function [keys,vals]=pairsToKeysVals(nPosArgs,varargin)
        if nargin < 2
            nPosArgs=0;
        end
        n=numel(varargin);
        inds=(1:2:n)+nPosArgs;
        keys=varargin(inds);
        vals=varargin(inds+1);
    end
    function [varsA,varsB]=splitPairs(vars,fldsInB)
        %vars={'a',33,'b',44,'cd',55,'ef',100};
        %fldsInB={'a','ef'};
        varsA=vars;

        varsB=cell(1,length(fldsInB)*2);
        ind=zeros(1,length(fldsInB));
        for i = 1:length(fldsInB)
            fld=fldsInB{i};
            ind(i)=find(cellfun(@(x) isequal(x,fld),vars));
            varsB{1,(i*2-1)}=vars{ind(i)};
            varsB{1,i*2}=vars{ind(i)+1};
        end
        ind=sort(ind,'descend');
        for i = ind
            varsA(i+1)=[];
            varsA(i)=[];
        end
    end
    function out=isPairs(varargin)
        out=cellfun(@ischar,varargin);
        out=mod(numel(out),2)==0 && all(out(1:2:end));
    end
    function vars=parsePairs(p,varargin)
    % good for chaning bad defaults in bulitin functions
    % assumes keepUnmatched
        p.KeepUnmatched=1;

        if isempty(varargin) || all(cellfun(@isempty,varargin))
            varargin=cell(0);
            p.parse();
        else
            p.parse(varargin{:});
        end
        vars=horzcat(struct2cells(p.Results),struct2cells(p.Unmatched));
    end
    function vars=readPairs(varargin)
    % good for chaning bad defaults in bulitin functions
    % assumes keepUnmatched

        Keys=varargin(1:2:end);
        Vals=varargin(2:2:end);
        if any(~cellfun(@ischar,Keys))
            error('KeyValue pairs are out of sync');
        end
        if numel(Keys)> numel(Vals)
            error('To many keyVlues');
        end
        if numel(Keys)< numel(Vals)
            error('To many Values');
        end
        vars=stuct(varargin{:});
    end
    function [objs,args]=splitMeta(str)
        re='[@\.]([A-Za-z0-9_]+)';
        objs=regexp(str,re,'tokens');
        objs=cellfun(@(x) x{1},objs,'UniformOutput',false);

        re2='[(,] *([A-Za-z0-9_]+)';
        args=regexp(str,re2,'tokens');
        args=cellfun(@(x) x{1},args,'UniformOutput',false);
    end
end
%%% TOGGLER INTERFACE
methods
    function setParent(obj,Parent)
        obj.Toggler.Parent=Parent;
    end
    function [exitflag,msg]=set(obj,name,val);
        if nargout > 1
            [exitflag,msg]=obj.Toggler.set(name,val);
        else
            obj.Toggler.set(name,val);
        end
    end
    function [out,exitflag,msg]=inc(obj,name,n,bWrap);
        if nargin < 4
            bWrap=[];
        end
        if nargout > 1
            [out,exitflag,msg]=obj.Toggler.inc(name,n,bWrap);
        else
            out=obj.Toggler.inc(name,n,bWrap);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods(Access=private)
    function obj=Args(OBJ,P,Opts,argsin);
        if isempty(Opts)
            obj.Opts=struct();
        else
            obj.Opts=Opts;
        end
        %XXX weird persisentent behavior matlab
        obj.dictr=containers.Map;
        obj.dictf=containers.Map;
        obj.ARGS=containers.Map;

        obj.OBJ=OBJ;
        obj.P=P;
        obj.nPosArgs=sum(cellfun(@isempty,P(:,1)));
        if length(argsin) == 1 && isstruct(argsin{1}) && numel(argsin{1}) > 1
            error('Detected input struct array with numel > 1.  This is likely due to nested structs in cell. Check your input and try again.')
        elseif length(argsin) == 1 && isstruct(argsin{1}) && numel(fieldnames(argsin{1})) > 0
            keys=fieldnames(argsin{1});
            vals=struct2cell(argsin{1});
            if obj.IgnoreUnmatched
                rmind=~ismember(keys,P(:,1));
                keys(rmind)=[];
                vals(rmind)=[];
            end
            obj.ARGS=containers.Map(keys,vals);
        elseif length(argsin) == 1 && isstruct(argsin{1})
            obj.ARGS=containers.Map();
        elseif length(argsin) == 1 && isa(argsin{1},'dict')
            obj.ARGS=argsin{1};
            if obj.IgnoreUnmatched
                rmind=~ismember(obj.Args.keys,P(:,1));
                keys(rmind)=[];
                vals(rmind)=[];
            end
        elseif length(argsin) > 1
            obj.bNotArgIn=false;
            [keys,vals]=Args.pairsToKeysVals(obj.nPosArgs,argsin{:});
            vals=cellfun(@Args.cellparsefun,vals,'UniformOutput',false);
            if isfield(Opts,'IgnoreUnmatched') && Opts.IgnoreUnmatched;
                rmind=~ismember(keys,P(:,1));
                keys(rmind)=[];
                vals(rmind)=[];
            end
            obj.ARGS=containers.Map(keys,vals);
        end
        obj.parse_own();
        obj.parse_p();
        obj.expand_structs();
        obj.parse_main();
        obj.parse_nested();
        obj.IP.Unmatched
        obj.parse_groups();
        obj.convert_output();
        if ~obj.KeepUnmatched && numel(fieldnames(obj.OUTUM)) > 0
            flds=fieldnames(obj.OUTUM);
            error(['Has Unmatched params:' newline '  ' strjoin(flds,[newline '  '])])
        end
    end
    function expand_structs(obj)
        dkees=keys(obj.dictr);
        nest=obj.nested(cellfun(@(x) ~isempty(x) && ischar(x),obj.nested(:,2)),:);
        [~,inds]=unique(nest(:,2));
        okees=nest(inds,2);

        bDICT=isa(obj.ARGS,'dict');

        FLDS=keys(obj.ARGS);
        for i = 1:length(FLDS)
            fld=FLDS{i};
            if ismember(fld,dkees)
                continue
            end
            if bDICT
                val=obj.ARGS{fld};
            else
                val=obj.ARGS(fld);
            end
            bDict=isa(val,'dict');
            bStruct=isa(val,'struct');
            if bStruct
                flds=cellfun(@(x) [fld x],Struct.getFields(val),'UniformOutput',false);
                newflds=cellfun(@(x) strjoin(x,'.'),flds,'UniformOutput',false);
                newvals=cellfun(@(x) getfield(val,x{2:end}),flds,'UniformOutput',false);
                bMem =cellfun(@(x) ismember(x,dkees),newflds);
                bMemS=cellfun(@(x) ismember(x{1},okees),flds);
            elseif bDict
                TODO
            else
                continue
            end

            if ~any(bMem) && ~any(bMemS)
                continue
            end
            bMemS
            fld
            newflds

            if bDICT
                obj.ARGS=remove(obj.ARGS,fld); % XXX CHECK
                for j = 1:length(newflds)
                    obj.ARGS{newflds{j}}=newvals{j};
                end
            else
                obj.ARGS=remove(obj.ARGS,fld);
                for j = 1:length(newflds)
                    obj.ARGS(newflds{j})=newvals{j};
                end
            end
            keys(obj.ARGS)
        end


    end
    function convert_output(obj)
        if isempty(obj.OBJ) && isnumeric(obj.OBJ)
            obj.OBJ=struct;
        end
        switch class(obj.OBJ)
            case 'dict'
                obj.out_as_dict();
            case 'struct'
                obj.out_as_struct();
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
    function parse_own(obj)
        P=Args.get_own_p();
        flds=fieldnames(obj.Opts);
        seen={};
        for i = 1:length(flds)
            fld=flds{i};
            val=obj.Opts.(fld);
            if ismember(fld,P(:,1));
                p=P(ismember(P(:,1),fld),:);
                name=p(1);
                if ismember(name,'seen')
                    obj.errors{end+1}={'errorValue',fld,val,true};
                    continue
                end
                seen{end+1}=name;

                fun=str2func(p{3});
                if ~fun(val)
                    obj.errors{end+1}={'errorValue',fld,val,true};
                    continue
                end
                obj.(fld)=val;
            else
                obj.errors{end+1}={'erroroption',fld,val,true};
            end
        end
        % TODO
        if ~isempty(obj.errors)
            obj.errors{:}
            error
        end
    end

    function parse_p(obj)
        IP=inputParser;
        if size(obj.P)>=2
            obj.bDefault=true;
            if size(obj.P)>=3
                obj.bTest=true;
            end
            if size(obj.P)>=4
                obj.bFlag=true;
            end
        end
        obj.nested=cell(size(obj.P,1),2);
        obj.toggles=cell(size(obj.P,1),2);
        obj.groups=cell(size(obj.P,1),1);
        for i = 1:size(obj.P,1);
            if obj.bDefault
                default=obj.P(i,2);
            else
                default=[];
            end

            %obj.P{i,1}
            f=['f' num2str(i)];
            name=obj.P{i,1};
            if iscell(name)
                %% HANDLE ALIASES
                obj.dictf(f)=name{1};
                for i = 1:length(name)
                    obj.dictr(name{i})=f;
                end
            else
                obj.dictf(f)=name;
                obj.dictr(name)=f;
            end

            %obj.P{i,3}
            if obj.bTest
                T=obj.P{i,3};
                if (ischar(T) && startsWith(T,'!')) || ( iscell(T) && size(T,2) == 3 && size(T,1) > 1 ) || isstruct(T) || isa(T,'dict')
                    if ischar(T)
                        cls=T(2:end);
                        obj.nested(i,:)={name cls};
                    else
                        obj.nested(i,:)={name T};
                    end
                    test=@(x) isempty(x) || ismember(class(x),{'dict','struct'});
                    obj.toggles(i,:)={name,test};
                elseif isnumeric(T) && (numel(T)==2 || numel(T)==3)
                    % min,max,inc
                    test=@(x) x >= T(1) && x <= T(end);
                    obj.toggles(i,:)={name,T};
                elseif iscell(T) || (isnumeric(T) && numel(T) > 3)
                    % list
                    if isnumeric(T)
                        T=num2cell(T);
                    end
                    test=@(x) ismember(x,T);
                    obj.toggles(i,:)={name,T};
                elseif regexp(T,'(is[bB]inary|islogical)(_e)?$')
                    test=Args.parse_test(T);
                    obj.toggles(i,:)={name,{false,true}};
                else
                    test=Args.parse_test(T);
                    obj.toggles(i,:)={name,test};
                end
            else
                test=@(varargin) true;
                obj.toggles(i,:)={name,test};
            end

            %obj.P{i,4}
            if obj.bFlag
                F=obj.P{i,4};
                if isnumeric(F)
                    obj.groups{i}(end+1)=F;
                    if ~ismember(F,obj.uGroups)
                        obj.uGroups(end+1)=F;
                    end
                elseif ischar(F)
                    for k = 1:length(F)
                        fl=F(k);
                        if Str.Num.is(fl)
                            fl=str2double(fl);
                            obj.groups{i}(end+1)=fl;
                            if ~ismember(fl,obj.uGroups)
                                obj.uGroups(end+1)=fl;
                            end
                        end
                    end
                end
            end

            IP.addParameter(f,default,test);
        end
        obj.IP=IP;
    end
    function parse_main(obj,in)
        obj.IP.CaseSensitive=false;
        obj.IP.KeepUnmatched=true;
        obj.IP.StructExpand=true;
        args=struct();
        flds=keys(obj.ARGS);
        kees=keys(obj.dictr);
        nUnm=0;
        args={};
        bDict=isa(obj.ARGS,'dict');
        for i = 1:length(flds)
            bUm=false;
            if bDict
                val=obj.ARGS{flds{i}};
            else
                val=obj.ARGS(flds{i});
            end
            if ismember(flds(i),kees)
                key=obj.dictr(flds{i});
            else
                nUnm=nUnm+1;
                key=['u' num2str(nUnm)];
                obj.dictf(key)=flds{i};
                obj.dictr(flds{i})=key;
                bUm=true;
            end
            % TEST = pp
            if obj.bTest && ~startsWith(key,'u')
                try
                    pp=obj.P{str2double(key(2:end)),3};
                catch ME
                    str2double(key(2:end))
                    bUm
                    obj.P
                    flds{i}
                    key
                    rethrow(ME)
                end
                mtch=numel(pp) == 1 && iscell(pp) && Str.RE.ismatch(pp,'^(is)?[Cc]harcell$');
            else
                pp=[];
                mtch=false;
            end
            if mtch && ischar(val)
                val={{val}};
            elseif obj.bNotArgIn && iscell(val)
                val={val};
            end
            bflag=false;
            if numel(pp)== 1 && iscell(pp) && Str.RE.ismatch(pp,'^(is)?[Cc]el[Ss]truct') && isstruct(val)
                val={args};
            elseif ~iscell(pp) && (isstruct(val) || isobject(val))
                bflag=true;
            end
            if isnumeric(val) && isempty(val)
                val={[]};
            end
            if bflag
                args=[args key 0];
                args{end}=val;
            else
                args=[args key val];
            end
        end

        try
            obj.IP.parse(args{:});
        catch ME
            m=Str.RE.match(ME.message,'[uf][0-9]+');
            ind=str2double(m(2:end));
            msg=regexprep(ME.message,'[uf][0-9]+',obj.dictf(m));
            %m
            error(ME.identifier,msg);
        end
        obj.IP=Obj.struct(obj.IP);
    end
    function parse_groups(obj)
        names=obj.P(:,1);
        if numel(obj.uGroups) == 1 && obj.uGroups(1)==0 || isempty(obj.uGroups)
            return
        end
        for i = 1:length(obj.uGroups)
            u=obj.uGroups(i);
            if u==0
                continue
            end
            bGroup=cellfun(@(x) ismember(u,x),obj.groups);
            if all(cellfun(@(x) ~isempty(obj.get_result(x)),names(bGroup)));
                return
            end
        end
        error('No parse groups were satisfied')
    end
    function parse_nested(obj)
        umfflds=fieldnames(obj.IP.Unmatched);
        umffldsO=umfflds;
        umflds=cellfun(@(x) obj.dictf(x) ,umfflds,'UniformOutput',false);
        for i = 1:length(obj.nested)
            if isempty(obj.nested{i,1})
                continue
            end
            fld=obj.nested{i,1};
            o=obj.nested{i,2};
            if ischar(o)
                spl=strsplit(o,'.');
                cls=spl{1};
                if length(spl) >= 2
                    meth=spl{2};
                else
                    meth='getP';
                end
                if length(spl) >= 3
                    args=spl(3:end);
                else
                    args={};
                end
                str=[cls '.' meth '(args{:});'];
                try
                    p=eval(str);
                catch ME
                    disp(str)
                    rethrow(ME);
                end
            else
                p=o;
                cls='';
            end

            ffld=obj.dictr(fld);
            %opts=obj.get_result_f(ffld);
            opts=struct();

            newflds=p(:,1);
            if ~isempty(umflds)
                reps={''};
                if ~isempty(cls)
                    reps=[reps [cls '.']];
                end
                for j = 1:length(reps)
                    [opts,umflds,umfflds]=obj.um_fun(newflds,umflds,umfflds,reps{j},opts);
                    if isempty(umflds)
                        break
                    end
                end
            end

            obj.IP.Unmatched
            opts
            out=Args.parse([],p,opts);
            obj.set_ip_result_f(ffld,out);
        end
        rmflds=umffldsO(~ismember(umffldsO,umfflds));
        if ~isempty(rmflds)
            obj.IP.Unmatched=rmfield(obj.IP.Unmatched,rmflds);
        end
        obj.IP.Unmatched
    end
    function [opts,umflds,umfflds]=um_fun(obj,newflds,umflds,umfflds,rep,opts)
        if ~isempty(rep)
            newflds=strcat(rep,newflds);
        end
        inds=ismember(umflds,newflds);
        if ~any(inds)
            return
        end
        fld=umflds{inds};
        fflds=umfflds{inds};
        val=obj.IP.Unmatched.(fflds);
        umflds(inds)=[];
        umfflds(inds)=[];

        if isstruct(opts)
            if contains(fld,'.')
                spl=strsplit(fld,'.');
                opts=setfield(opts,spl{:},val);
            else
                opts.(fld)=val;
            end
        elseif isa(opts,'dict')
            opts(fld)=val;
        elseif iscell(opts)
            opts{end+1}=fld;
            opts{end+1}=val;
        end
    end
    function out=get_result(obj,fld)
        out=obj.get_result_f(obj.dictr(fld));
    end
    function set_result_f(obj,DEST,fld)
        flds=strsplit(obj.dictf(fld),'.');
        obj.(DEST)=setfield(obj.(DEST),flds{:},obj.get_result_f(fld));

        %obj.OUT.(obj.dictf(flds{i}))=obj.get_result_f(flds{i});
    end
    function out=get_result_f(obj,fld)
        if ismember(fld,obj.IP.UsingDefaults)
            out=obj.IP.Results.(fld){1};
        else
            out=obj.IP.Results.(fld);
        end
    end
    function set_ip_result_f(obj,fld,val)
        if ismember(fld,obj.IP.UsingDefaults)
            obj.IP.Results.(fld){1}=val;
        else
             obj.IP.Results.(fld)=val;
        end
    end
    function out_as_object(obj);
        out=obj.IP.Results;
        flds=fieldnames(out);
        for i = 1:length(flds)
            obj.set_result_f('OBJ',flds{i});
        end
        obj.OUT=obj.OBJ;

        flds=fieldnames(obj.IP.Unmatched);
        obj.OUTUM=struct();
        for i = 1:length(flds)
            obj.OUTUM.(obj.dictf(flds{i}))=obj.IP.Unmatched.(flds{i});
        end
    end
    function out_as_struct(obj);
        out=obj.IP.Results;
        flds=fieldnames(out);
        obj.OUT=struct();
        for i = 1:length(flds)
            obj.set_result_f('OUT',flds{i});
        end

        flds=fieldnames(obj.IP.Unmatched);
        obj.OUTUM=struct();
        for i = 1:length(flds)
            obj.OUTUM.(obj.dictf(flds{i}))=obj.IP.Unmatched.(flds{i});
        end
    end
    function out_as_dict(obj);
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
    function out_as_cell(obj)
        obj.out_as_struct();
        obj.OUT=[fieldnames(obj.OUT) struct2cell(obj.OUT)];
        obj.OUTUM=[fieldnames(obj.OUTUM) struct2cell(obj.OUTUM)];
    end
    function get_toggler(obj)
        out=~cellfun(@isempty,obj.toggles(:,1));
        n=sum(out);
        if n < 1
            return
        end
        names=cell(n,1);
        T=cell(n,1);
        vals=cell(n,1);
        for i = 1:length(obj.toggles)
            % XXX isint, isInt, isInt_e
            names{i}=obj.toggles{i,1};
            T{i}=obj.toggles{i,2};
            if isa(obj.OUT,'dict')
                vals{i}=obj.OUT(names{i});
            elseif isstruct(obj.OUT)
                vals{i}=obj.OUT.(names{i});
            end
        end
        if isobject(obj.OBJ) && ~isa(obj.Obj,'Table') && ~isa(obj.Obj,'dict')
            Parent=obj.OBJ;
        else
            Parent=[];
        end
        obj.Toggler=Toggler(names,T,vals,Parent);
    end
%% ERROR
    function errorOption(obj,name,bSelf)
        if nargin < 4
            bSelf=false;
        end
        str='Invalid option ''%s'' for ''%s.'''; %
        if bSelf
            typ='Argsr';
        elseif ~isempty(obj.objName)
            typ=obj.objName;
        else
            typ=class(obj.OBJ);
        end
        errors{end+1}=sprintf(str,fld,typ);
    end
    function errorMultiple(obj,fld,bSelf)
        if nargin < 4
            bSelf=false;
        end
        str='Multiple instances of ''%s'' option ''%s.'''; %
        if bSelf
            typ='Argsr';
        else
            typ=class(obj.OBJ);
        end
        obj.errors{end+1}=sprintf(str,typ,fld);
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
        str=['Invalid value ''%s'' for ''%s'' option ''%s.''']; %
        if bSelf
            typ='Argsr';
        else
            typ=class(obj.OBJ);
        end
        obj.errors{end+1}=sprintf(str,val,typ,fld);
    end
end
methods(Static, Access=private);
    function x=cellparsefun(x)
        if iscell(x)
            x={x};
        end
    end
    function P=get_own_p()
        % NOTE JUST A DUMMY FOR REFERENCE
        P={'bQuiet', false, '@Args.isBinary';
           'KeepUnmatched', false, '@Args.isBinary';
           'IgnoreUnmatched',false,'@Args.isBinary';
           'CaseSensitive', true, '@Args.isBinary';
           'StructExpand', true, '@Args.isBinary';
           'rmFields', {}, '@iscell';
           'objName','','@ischar';
          };
    end
%%% MISC TESTS
end
methods(Static)
    function test=parse_test(test)
        if isempty(test)
            test=@(x) Args.istrue;
            return
        elseif isa(test,'function_handle')
            return
        end
        % is.(class)
        test=regexprep(test,'^is\.(.[A-Za-z0-9]+)','isa(x,''$1'')');
        test=regexprep(test,'^(is)?([Cc]harcell|[cC]ellstruct|[Bb]inary|[iI]nt|[dD]ouble|[sS]ingle)','Args.is$2');
        test=regexprep(test,'^(struct|char|numeric|logical|cell)','is$1');
        flags=strsplit(test,'_');
        fInds=cellfun(@(x) Str.RE.ismatch(x,'^(a|e|([0-9]+(x[0-9]+)+)|^[0-9]+)$'),flags);
        if sum(fInds)==0
            if ~startsWith(test,'@')
                test=[ '@' test ];
            end
            test=str2func(test);
            return
        end
        fInds=~logical(cumprod(~fInds));
        test=strjoin(flags(~fInds));
        if ismethod('Args',test)
            test=['Args.' test];;
        end
        if ~endsWith(test,')')
            test=[test '(x)'];
        end
        flags=flags(fInds);

        for i = 1:length(flags)
            flag=flags{i};
            switch flag
                case 'i'
                    test=['ismember(x,' test ')'];
                case 'e'
                    test=['isempty(x)  || (' test  ')'];
                case 'a'
                    test=['all(' test  ')'];
                otherwise
                    if Str.Num.isInt(flag)
                        test=['numel(x)==' flag ' && (' test ')'];
                    elseif Str.RE.ismatch(flag,'^[0-9x]+$')
                        flag=['[' Num.toStr(strrep(flag,'x',' ')) ']'];
                        test=['isequal(size(x),' flag ')  && (' test ')'];
                    end
            end
        end

        if ~startsWith(test,'@') && ~isempty(flags)
            test=[ '@(x) ' test ];
        elseif ~startsWith(test,'@')
            test=[ '@' test];
        end
        test=str2func(test);
    end
    function out=isCharList(in)
        out=ischarlist(in);
    end
    function out=ischarlist(in)
        out=ischar(in) || Args.ischarCell(in);
    end
    function out=isCharCell(in)
        out=Args.ischarcell(in);
    end
    function out=ischarcell(in)
        if ~iscell(in)
            out=false;
            return
        end
        try
            out=all(cellfun(@(x) ischar(x) & ~isempty(x),in),'all');
        catch
            out=all(all(cellfun(@(x) ischar(x) & ~isempty(x),in)));
        end
    end
    function out=isCellStruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
    end
    function out=iscellstruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
    end
    function isnormal(in)
        out=isnumeric(in) && in <= 1 && in >=0;
    end
    function out=isNormal(in)
        out=Arg.isnormal(in);
    end
    function out=isOptions(in)
        out=isoptions(in);
    end
    function out=isoptions(in)
        out=ismember(class(in),{'dict','struct'});
    end
    function out =isBinary(in)
        out=Args.isbinary(in);
    end
    function out =isbinary(in)
        if islogical(in)
            out=true;
        elseif ~isnumeric(in)
            out=false;
            return
        end
        out=isequal(in,1) | isequal(in,0);

    end
    function out =isInt(in)
        out=isint(in);
    end
    function out = isint(in)
        if ~isnumeric(in)
            out=0;
            return
        end
        out=~(mod(in,1));
    end
    function out=isDouble(in)
        out=Args.isDouble(in);
    end
    function out = isdouble(in)
        out=isa(in,'double');
    end
    function out=isSingle(in)
        out=Args.issingle(in);
    end
    function out = issingle(in)
        out=isa(in,'single');
    end
    function out= isdict(in)
        out=isa(in,'dict');
    end
    function out= isTrue(varargin)
        out=true;
    end
    function out= istrue(varargin)
        out=true;
    end
%%%
end
methods(Static, Hidden)
    function out=structToCell(S)
        S
        dk
    end
    function TEST(obj)
        P={'bArg1',false, 'Binary'; ...
           'bArg2',[], 'Binary_e'; ...
           'cArg3','abc', 'ischarcell'; ...
           'ccArg4',{'abc'}, 'ischarcell'; ...
           'csbArg5',{struct()}, 'iscellstruct'; ...
           'dblArg6',double(3), 'double'; ...
           'snlArg7',single(3), 'single'; ...
           'intArg8',3, 'int'; ...
           'intaeArg9',[3 3], 'int_a_e'; ...
           'intaeArg10',[], 'int_a_e'; ...
           'emArg7',[], []; ...
           'i1Arg7',3,'int_1';
           'i1x31Arg7',[1 2 3],'int_1x3';
           'i1x31Arg7',[1 2 3],'struct';
          };

        cc=cell(2,1);
        cc{1}=struct('a',2,'b',1);
        cc{2}=struct('a',2,'b',1);
        vargARGS={'bArg1',true, ...
                  'bArg2',true, ...
                  'dblArg6',88, ...
                  'snlArg7',single(88), ...
                  'intArg8',int8(88), ...
                  'cArg3',{'def'}, ...
                  'ccArg4','def', ...
                  'um1',{'abc'},...
                  'um2','abc',...
                  'csbArg5',cc,...
                   };


        parseOpts=struct('KeepUnmatched',true);

        % NO ARGS
        [OUT,UM]=Args.parse(dict(),P,parseOpts);
        [OUT,UM]=Args.parse(struct(),P,parseOpts);
        [OUT,UM]=Args.parse({},P,parseOpts);


        % ARGS
        [OUT,UM]=Args.parse({},P,parseOpts,vargARGS{:});
        [OUT,UM]=Args.parse(struct(),P,parseOpts,vargARGS{:});
        %OUT.ccArg4
        %OUT.cArg3
        %OUT.dblArg6
        %OUT.snlArg7
        %dk

        % as struct
        %[OUT,UM]=Args.parse({},P,parseOpts,struct(vargARGS{:}))
        [OUT,UM]=Args.parse(dict(),P,parseOpts,dict(vargARGS{:}))
        OUT{'cArg3'}
        OUT{'ccArg4'}
        OUT{'csbArg5'}
        [OUT,UM]=Args.parse(dict(),P,parseOpts,vargARGS{:})
        OUT{'cArg3'}
        OUT{'ccArg4'}
        OUT{'csbArg5'}

        parseOpts=struct('KeepUnmatched',false);
        % UNMATCHED
        [OUT,UM]=Args.parse(dict(),P,parseOpts,vargARGS{:})
    end
    function test_groups()
        P={ ...
            'posXYZm',     [],'','1';
            'vrs',         [],'',2;
            'vrg',         [],'',2;
            'posXYpix',    [],'',3;
            'los',         [],'',4;
            'depthC',      [],'',4;
            'A',           [],'',0;
            'B',           [],'',0;
        };
        1
        opts=struct();
        opts.posXYZm=[1 2 3];
        Args.parse([],P,opts);

        2
        opts.vrs=0;
        Args.parse([],P,opts);

        3
        opts=rmfield(opts,'posXYZm');
        try
            Args.parse([],P,opts);
        catch ME
            disp(ME.message)
        end

        4
        P={...
            'A',           [],'',0;
            'B',           [],'',0;
        };
        Args.parse([],P,struct());
    end
    function test_aliases()
        P={ ...
            {'XYZm','posXYZm'},     [],'';
            'vrs',         [],'';
            'vrg',         [],'';
            'posXYpix',    [],'';
            'los',         [],'';
            'depthC',      [],'';
            'A',           [],'';
            'B',           [],'';
        };
        1
        opts=struct();
        opts.posXYZm=[1 2 3];
        out=Args.parse([],P,opts);
        out

        2
        opts=struct();
        opts.XYZm=[2 3 4];
        out=Args.parse([],P,opts);
        out

        3
        opts.posXYZm=[1 2 3];
        opts.XYZm=[2 3 4];
        out=Args.parse([],P,opts);
        out
    end
    function test_struct_name()
        P={ ...
            {'fld1.fld2.fld3','fld3'}, 3,'';
            'vrs',         [],'';
            'vrg',         [],'';
            'posXYpix',    [],'';
            'los',         [],'';
            'depthC',      [],'';
            'A',           [],'';
            'B',           [],'';
        };

        1
        opts=struct;
        out=Args.parse([],P,opts);
        out.fld1.fld2.fld3;

        2
        opts=struct;
        opts.fld1.fld2.fld3=2;
        out=Args.parse([],P,opts);
        out.fld1.fld2.fld3

        3
        opts=struct;
        opts.fld3=3;
        out=Args.parse([],P,opts);
        out.fld1.fld2.fld3
    end
    function test_toggler()
        P={ ...
            'LorRorC', [],   {'L','R','C'};
            'slider', [],    [0 .1 1];
            'bFlag',  [],    'isbinary';
        };
        opts.LorRorC='L';
        opts.slider=.5;
        opts.bFlag=0;
        [out,obj]=Args.parse([],P,opts);

        % val=obj.inc('slider',2)
        % val=obj.inc('slider',-1)
        % val=obj.inc('slider',20)
        % val=obj.inc('slider',-20)
        % val=obj.inc('slider',3)

        val=obj.inc('LorRorC',1)
        val=obj.inc('LorRorC',2)
        val=obj.inc('LorRorC',-1)
        val=obj.inc('LorRorC',-3)
        val=obj.inc('LorRorC',-2)

        %val=obj.inc('bFlag',1)
        %val=obj.inc('bFlag',-1)
        %val=obj.inc('bFlag',-1)
    end
    function test_nested()
        1
        P={ ...
            'LorRorC', [],   {'L','R','C'};
            'slider',  [],    [0 .1 1];
            'bFlag',   [],    'isbinary';
            'Opts',    [],    '!TestingObj';
        };
        opts.LorRorC='L';
        opts.slider=.5;
        opts.bFlag=0;
        opts.prop1='A';
        %opts.TestingObj
        [out]=Args.parse([],P,opts);

        2
        P={ ...
            'LorRorC', [],   {'L','R','C'};
            'slider',  [],    [0 .1 1];
            'bFlag',   [],    'isbinary';
            'Opts',    [],    TestingObj.getP();
        };
        opts.LorRorC='L';
        opts.slider=.5;
        opts.bFlag=0;
        opts.prop1='A';
        %opts.TestingObj
        [out]=Args.parse([],P,opts);
        out.Opts

        3
        P={ ...
            'LorRorC', [],   {'L','R','C'};
            'slider',  [],    [0 .1 1];
            'bFlag',   [],    'isbinary';
            'Opts',    [],    '!TestingObj';
        };
        opts.LorRorC='L';
        opts.slider=.5;
        opts.bFlag=0;
        opts.TestingObj.prop1='A';
        %opts.TestingObj
        [out]=Args.parse([],P,opts);
    end
end
end
