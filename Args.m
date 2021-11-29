classdef Args < handle
%%% Arg.parse(PARENT, P, varargin)
properties
   nPosArgs
   dictf=containers.Map
   dictr=containers.Map
   IP
   ARGS=containers.Map
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

   bDefault
   bTest=false

   OUT=struct
   OUTUM
end
methods(Static)
%%% MAIN INTERFACES
    function out=parse(parent,P,varargin)
        obj=Args(parent,P,struct(),varargin);
        out=obj.OUT;
    end
    function [out,unmatched]=parseLoose(parent,P,varargin)
        Opts=struct('KeepUnmatched',true);
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
        unmatched=obj.OUTUM;
    end
    function [out]=parseIgnore(parent,P,varargin)
        Opts=struct('KeepUnmatched',false,'IgnoreUnmatched',true);
        obj=Args(parent,P,Opts,varargin);
        out=obj.OUT;
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
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods(Access=private)
    function obj=Args(OBJ,P,Opts,argsin);
        if isempty(Opts)
            obj.Opts=struct();
        else
            obj.Opts=Opts;
        end

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
        obj.parse_main();
        obj.convert_output();
        if ~obj.KeepUnmatched && numel(fieldnames(obj.OUTUM)) > 0
            flds=fieldnames(obj.OUTUM);
            error(['Has Unmatched params:' newline '  ' strjoin(flds,[newline '  '])])
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
        end
        for i = 1:size(obj.P,1);
            if obj.bDefault
                default=obj.P(i,2);
            else
                default=[];
            end
            if obj.bTest
                %obj.P{i,3}
                test=Args.parse_flags(obj.P{i,3});
            else
                test=@Args.isTrue;
            end
            %if strcmp(obj.P{i,1},'cArg3')
            %    test
            %end
            f=['f' num2str(i)];
            obj.dictf(f)=obj.P{i,1};
            obj.dictr(obj.P{i,1})=f;
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
            end
            if obj.bTest
                pp=obj.P{str2double(key(2:end)),3};
                mtch=iscell(pp) && Str.RE.ismatch(pp,'^(is)?[Cc]harcell$');
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
            if iscell(pp) && Str.RE.ismatch(pp,'^(is)?[Cc]el[Ss]truct') && isstruct(val)
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
            %args{ind*2}
            error(ME.identifier,msg);
        end
    end
    function out_as_object(obj);
        out=obj.IP.Results;
        flds=fieldnames(out);
        for i = 1:length(flds)
            if ismember(flds{i},obj.IP.UsingDefaults)
                obj.OBJ.(obj.dictf(flds{i}))=out.(flds{i}){1};
            else
                obj.OBJ.(obj.dictf(flds{i}))=out.(flds{i});
            end
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
            if ismember(flds{i},obj.IP.UsingDefaults)
                obj.OUT.(obj.dictf(flds{i}))=out.(flds{i}){1};
            else
                obj.OUT.(obj.dictf(flds{i}))=out.(flds{i});
            end
        end

        flds=fieldnames(obj.IP.Unmatched);
        obj.OUTUM=struct();
        for i = 1:length(flds)
            obj.OUTUM.(obj.dictf(flds{i}))=obj.IP.Unmatched.(flds{i});
        end
    end
    function out_as_dict(obj);
        out=obj.IP.Results;
        flds=fieldnames(out);
        obj.OUT=dict(true);
        for i = 1:length(flds)
            if ismember(flds{i},obj.IP.UsingDefaults)
                obj.OUT{obj.dictf(flds{i})}=out.(flds{i}){1};
            else
                obj.OUT{obj.dictf(flds{i})}=out.(flds{i});
            end
        end

        flds=fieldnames(obj.IP.Unmatched);
        obj.OUTUM=dict(true);
        for i = 1:length(flds)
            obj.OUTUM{obj.dictf(flds{i})}=obj.IP.Unmatched.(flds{i});
        end
    end
    function out_as_cell(obj)
        obj.out_as_struct();
        obj.OUT=[fieldnames(obj.OUT) struct2cell(obj.OUT)];
        obj.OUTUM=[fieldnames(obj.OUTUM) struct2cell(obj.OUTUM)];
    end
%% ERROR
    function errorOption(obj,name,bSelf)
        if nargin < 4
            bSelf=false;
        end
        str=['Invalid option ''%s'' for ''%s.''']; %
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
        str=['Multiple instances of ''%s'' option ''%s.''']; %
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
    function test=parse_flags(test)
        if isempty(test)
            test=@(x) Args.istrue;
            return
        elseif isa(test,'function_handle')
            return
        end
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
        test=[strjoin(flags(~fInds)) '(x)'];
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
    function P=get_own_p()
        % NOTE JUST A DUMMY FOR REFERENCE
        P={'bQuiet', false, '@Args.isBinary';
           'KeepUnmatched', false, '@Args.isBinary';
           'IgnoreUnmatched',false,'@Args.isBinary';
           'CaseSensitive', true, '@Args.isBinary';
           'StructExpand', true, '@Args.isBinary';
           'rmFields', {}, '@iscell';
           'objName','','@ischar'
          };
    end
%%% MISC TESTS
end
methods(Static)
    function out=isCharCell(in)
        out=Args.ischarcell(in);
    end
    function out=ischarcell(in)
        if ~iscell(in)
            out=0;
            return
        end
        out=all(cellfun(@(x) ischar(x) & ~isempty(x),in),'all');
    end
    function out=isCellStruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
    end
    function out=iscellstruct(in)
        out=iscell(in) && all(cellfun(@isstruct,in));
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
end
end
