classdef Args < handle & ArgsCon & ArgsTest
%% TODO
%%   - Flags
%%        3 FLAG/F
%%   - private names
%%   - DON'T ALLOW DUPLICATES
%%        args or P
%%   - _e is implied
%%   1
%%     1name PPositiongal arg 1
%%
%%
%%   3
%%     !object in 3 & 1 = construct
%%   5 casting
%%   4
%%     Group parsing - specify names
%%     ?toggler with groups
%%   2
%%     meta in defaults
%%       @Parent.prop
%%       @Param
%%       @Parent.fun(x)
%%       @Parent.fun(@Param,x)
%%       @fun(@Param)
%%
%% P columns
%%  1 - names
%%        main name = 1
%%            !name - matches class in 3
%%        aliases 2:end
%%        'opts.fld.val' -> struct
%%        remove value from struct if exists as alias  e.g. {'LorRorC','Opts.LorRorC'},[],   {'L','R','C'}; 'Opts' ....
%%  3 - tests/nested
%%        struct => nestedP
%%        char starting with ! => nested P
%%        char => function
%%        [min,[inc,]max]
%%        {values}
%%  4 - flags
%%        numbers = groups
%%        - same abs(integer) == same group
%%        - 0 is optional, independent
%%        - 1 is required, independent
%%        - > 1 is required dependent
%%        - < 0 is optional dependent

%%% MAIN INTERFACES
methods(Static)
    function [out,dummy,toggler,obj]=parse(parent,P,varargin)
        st=dbstack(); st=st(2:end);

        obj=ArgsCon(parent,P,struct('nout',nargout,'stack',st,'bNested',false),varargin);

        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
        obj.OBJ=[];

        if ~isempty(errors); throwAsCaller(errors); end

        dummy=[];
        toggler=obj.Toggler;
    end
    function [out,unmatched,toggler,obj]=parseLoose(parent,P,varargin)
        st=dbstack(); st=st(2:end);

        Opts=struct('caller',st(2).name,'nout',nargout,'stack',st,'KeepUnmatched',true,'bNested',false);
        obj=ArgsCon(parent,P,Opts,varargin);

        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
        obj.OBJ=[];

        if ~isempty(errors); throwAsCaller(errors); end
        toggler=obj.Toggler;
    end
    function [out,dummy,toggler,obj]=parseIgnore(parent,P,varargin)
        st=dbstack(); st=st(2:end);

        Opts=struct('caller',st(2).name,'nout',nargout,'stack',callr,'KeepUnmatched',false,'IgnoreUnmatched',true,'bNested',false);
        obj=ArgsCon(parent,P,Opts,varargin);

        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
        obj.OBJ=[];


        if ~isempty(errors); throwAsCaller(errors); end
        dummy=[];
        toggler=obj.Toggler;
    end
    function [out,dummy,toggler,obj]=parseKeep(parent,P,varargin)
        st=dbstack();
        st=st(2:end);

        Opts=struct('caller',st(2).name,'nout',nargout,'stack',callr,'KeepUnmatched',true,'IgnoreUnmatched',true,'bNested',false);
        obj=ArgsCon(parent,P,Opts,varargin);

        errors=obj.return_errors();
        out=obj.OUT;
        unmatched=obj.OUTUM;
        obj.OBJ=[];

        if ~isempty(errors); throwAsCaller(errors); end
        dummy=[];
        toggler=obj.Toggler;
    end
    function [out,dummy,toggler,obj]=test_(parent,P,varargin)
        st=dbstack();
        st=st(2:end);

        [obj,out,errors]=ArgsCon(parent,P,struct('nout',nargout,'stack',st,'bNested',false,'bDebug',true),varargin);
        obj=ArgsCon(parent,P,Opts,varargin);
        out=obj.OUT;
        if ~isempty(errors); throwAsCaller(errors); end
        dummy=[];
        toggler=obj.Toggler;
    end
%% UTIL
    function opts=group(p,argsin)
        nall=length(argsin);
        bVarg=strcmp(p{end},'varargin');
        p=p(1:end-bVarg);
        npos=length(p);

        % if first input is struct and rest are empty, handle as all params
        if npos > 1 && nall == 1 & isstruct(argsin{1})
            opts=argsin{1};
            return
        end

        % separate PPositiongal from variable
        if npos == nall
            pargs=argsin;
            vargs={};
        elseif npos < nall
            pargs=argsin(1:npos);
            vargs=argsin(npos+1:end);
        else
            % fill in empty if don't exist
            pargs=[allargs repmat([],npos-nall)];
            vargs={};
        end

        pargs=[p; pargs];
        if length(vargs) == 1 && isstruct(vargs{1})
            % if first varg is a struct, handle as all vargs
            opts=struct(pargs{:});
            opts=Struct.merge(opts,vargs{1}); % SLOW XXX
        else
            opts=struct(pargs{:}, vargs{:});
        end
    end
    function Out=defaults(P)
        Out=struct();
        bDefaults=size(P,2)>1;
        for i = 1:size(P,1)
            if iscell(P{i,1})
                name=P{i,1}{1};
            else
                name=P{i,1};
            end
            if bDefaults
                Out.(name)=P{i,2};
            else
                Out.(name)=[];
            end
        end
    end
    function toFlags(P,varargin)
        for i = 1:length(vararign)
        end
    end
    function OUT=resolve(P,varargin)
        % BASIC HANDLING OF FLAGS AND ALIASES
        % DOES NOT HANDLE CLASSES, TOGGLES, UNMATCHED
        names=P(:,1);
        C=containers.Map;
        NAMES=cell(length(names),1);
        for i = 1:length(names)
            if iscell(names{i})
                name=names{i}{1};
                for j = 1:length(names{i})
                    alias=names{i}{j};
                    C(names{i}{j})=alias;
                end
            else
                name=names{i};
                C(names{i})=name;
            end
            NAMES{i}=name;
        end
        kees=keys(C);

        N=length(varargin);
        bLastArg=false;
        for i = 1:N
            if ismember(varargin{i},kees)
                if bLastArg
                    OUT.(newName)=P{Pind,2};
                end
                newName=C(varargin{i});
                Pind=ismember(NAMES,newName);
                if ismember(P{Pind,3},{'F','FLAG'}) && i+1 <= N && ~Num.isBinary(varargin{i+1})
                    OUT.(newName)=true;
                    bLastArg=false;
                else
                    bLastArg=true;
                    OUT.(newName)=true;
                end
            elseif bLastArg
                OUT.(newName)=varargin{i};
            elseif ischar(varargin{i})
                error('Unmatched parameter: %s',varargin{i});
            else
                error('detected value without a key no. %d',i)
            end
        end
    end
    function [parent,opts]=applyIf(parent,opts)
        bObj=isobject(parent);
        bStruct=isstruct(opts);
        flds=fieldnames(opts);
        for i = 1:length(flds)
            fld=flds{i};
            if bObj && Obj.hasprop_fast(parent,fld)
                parent.(fld)=opts.(fld);
                opts=rmfield(opts,fld);
            elseif bStruct && isfield(parent,fld)
                parent.(fld)=opts.(fld);
                opts=rmfield(opts,fld);
            end
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
    function [val,varargin,bSuccess]=getPair(name,varargin)
        ind=find(cellfun(@(x) isequal(x,name),varargin));
        if ~isempty(ind)
            val=varargin{ind+1};
            varargin(ind+1)=[];
            varargin(ind)=[];
            bSuccess=true;
        else
            val=0;
            bSuccess=false;
        end
    end
    function out=getNPosArgs(varargin)
        n=length(varargin);
        nPairs=find(cumprod(cellfun(@ischar,varargin(end-1:-2:1))),1,'last');
        if isempty(nPairs)
            nPairs=0;
        end
        out=n-nPairs*2;
    end
    function [keys,vals,posVals,nPosArgs]=pairsToKeysVals(varargin)
        nPosArgs=Args.getNPosArgs(varargin{:});
        n=numel(varargin);
        inds=(1:2:n)+nPosArgs;
        keys=varargin(inds);
        vals=varargin(inds+1);
        posVals=varargin(1:nPosArgs);
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
    function [args,str]=splitMetaArgs(str)
        re='[(,] *(@{0,1}[A-Za-z]{1}[A-Za-z0-9_.]*)';
        args=regexp(str,re2,'tokens');
        args=cellfun(@(x) x{1},args,'UniformOutput',false);

        str=regexprep(str,re,'');
    end
    function [objs,args,str]=splitMeta(str)
        re1='[@\.]([A-Za-z0-9_]+)';
        objs=regexp(str,re1,'tokens');
        objs=cellfun(@(x) x{1},objs,'UniformOutput',false);

        re2='[(,] *([A-Za-z0-9_]+)';
        args=regexp(str,re2,'tokens');
        args=cellfun(@(x) x{1},args,'UniformOutput',false);
        str=regexprep(str,re1,'');
        str=regexprep(str,re2,'');
    end
end
%%% TOGGLER INTERFACE
methods
    function setParent(obj,Parent)
        obj.Toggler.Parent=Parent;
    end
    function [exitflag,msg]=set(obj,name,val)
        if nargout > 1
            [exitflag,msg]=obj.Toggler.set(name,val);
        else
            obj.Toggler.set(name,val);
        end
    end
    function [out,exitflag,msg]=inc(obj,name,n,bWrap)
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
end
