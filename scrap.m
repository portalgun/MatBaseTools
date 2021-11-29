
                    if bCell(i-1)
                        cellflag=true;
                        celllvl=lastLvlN(end);
                        lastLvlN(end+1)=nl;

                        if length(lastLvlN)==2
                            R(KEYS{end})=[];
                            KEYS{end+1}=strrep(KEYS{end},':','');
                            R{KEYS{end}}=cell(0,1);
                            STR=['R{KEYS{end}}{end+1,1}=key;' ];
                            STR
                            lastLvlN
                            R
                            eval(STR);
                        else
                            k=strjoin(KEYS(1:end-1),'''}{''');
                            str=['R{''' k  '''}(''' KEYS{end} ''')=[];'];
                            eval(str);
                            KEYS{end}=strrep(KEYS{end},':','');
                            str=['R{''' strjoin(KEYS,'''}{''') '''}=cell(0,1);' ];
                            eval(str);

                            eval(STR);
                        end
                        Headers{num2str(hc)}=KEYS{end};


                    else


                    % get parent val
                    str=['pval=r{''' strjoin(keys,'''}{''') '''};' ];
                    eval(str);

                    %chnage parent val

                    eval(str);

                    % nest old parentval





                str=['r{''' strjoin(keys,'''}{''') '''}{0}=pval;' ];








                    if cellflag && lastLvlN(end)>=celllvl;
                        cellflag=false;
                    end


            if bFirst(i)
                cellflag=false;

                R{key}=val;

                continue
            elseif bHeaders(i)
                cellflag=false;

                KEYS={key};
                R{key}=dict(true);
                lastLvlN=0;

                hc=hc+1;
                Headers{num2str(hc)}=key;

                continue


    function find_headers(lines)
        re='^([ \t]+)(.*$)';
        if isempty(tk2)
            nl2=0;
        else
            nl2=length(tk2{1}{1});
        end
        tk2=regexp(lines{1},re,'tokens');
        for i = 1:length(lines)
            line=lines{i};
            nl=nl2;
            nll=lastN(end);
            lastN=0;
            if i < length(lines)
                tk2=regexp(lines{i+1},re,'tokens');
                if isempty(tk2)
                    nl2=0;
                else
                    nl2=length(tk2{1}{1});
                end
            end

            if nl2 > nl
                bHeaderStart(i)=true;
                val0=val;
                val=dict(true);
            end
        end
    end

%% CFG
    %%
    function obj=template_eval(obj)
        obj.Options=Cfg.subclass_eval_rec(dict(true),obj.Options);
    end
    function obj=meta_eval(obj)
        Opts=dict(true);
        flds=fieldnames(obj.Options);
        for i =1:length(flds)
            obj.Options{flds{i}}=obj.meta_eval_rec(obj.Options{flds{i}},Opts,'\$\$',obj.fname);
        end
    end
    function obj=meta_eval_meta(obj)
        Opts=dict(true);
        callerVars={};
        [obj.Options,obj.callerVars]=obj.meta_eval_meta_rec(obj.Options,obj.Options,Opts,'\$',callerVars);
    end

    function Opts=template_eval_rec(new,Opts)
        kees=Opts.keys;
        tFull=kees(contains(kees,'@'));
        spl=strsplit(tFull,'@');
        tName=spl{1};
        tArg=spl{1};
        for i = 1:length(Opts)
            if contains(keeps,'.')
                spl=strsplit(keeps,'.');
                sName=spl{1};
                sArg=spl{i};
                %ismember(sName,tName)
            end
            if isa(Opts{i},'dict')
                Cfg.template_eval_rec(Opts{i});
            end
        end
    end
    function [S]=meta_eval_rec(S,Opts,chara,fname)
        if ~iscell(S) && numel(S)==1 && isnan(S)
            S=dict(true);
            return
        end

        Oflds=fieldnames(Opts);
        bVal=false;
        if isa(S,'dict')
            flds=fieldnames(S);
            for i = 1:length(flds)
                fld=flds{i};
                if ~ismember(fld,Oflds)
                    Oflds{end+1,1}=fld;
                    Opts{fld}=S{fld};
                end
            end
        else
            bVal=true;
            S=dict(true,'fld',S);
            flds={'fld'};
        end

        m=strrep(chara,'\','');
        for i = 1:length(flds)
            fld=flds{i};

            if ischar(S{fld}) && contains(S{fld},m)


                % EVALUATE DEPNDENCIES IF EXIST
                outP=Str.RE.match(S{fld},[chara '[a-zA-Z]+[a-zA-Z_0-9]*\.']);
                if ~isempty(outP)
                    outPfull=Str.RE.match(S{fld},[chara '[a-zA-Z]+[a-zA-Z_0-9]*\.\$[a-zA-Z]+[a-zA-Z_0-9]*']);
                    outPvar=strrep(outPfull,outP,'');
                    outPvar=outPvar(2:end);
                    P=outP(3:end-1);
                    [dire]=Fil.parts(fname);
                    file=[dire P '.config'];
                    Opts2=Cfg.read(file);
                    if isfield(Opts2,outPvar)
                        S{fld}=strrep(S{fld},outPfull,Opts2.(outPvar));
                    end
                end

                % HANDLE ENVIRONMENTAL VARS
                out=Str.RE.match(S{fld},[chara '[a-zA-Z]+[a-zA-Z_0-9]*']);
                var=out(length(m)+1:end);
                env=builtin('getenv',var); % SLOW XXX
                if ~isempty(env)
                    S{fld}=strrep(S{fld},out,env);
                end

            elseif isa(S{fld},'dict')
                S{fld}=Cfg.meta_eval_rec(S{fld},Opts,chara);
            end
        end
        if bVal
            S=S{'fld'};
        end
    end
    function [S,callerVars]=meta_eval_meta_rec(SAll,S,Opts,chara,callerVars)
        Oflds=fieldnames(Opts);
        bVal=false;
        if isa(S,'dict')
            flds=fieldnames(S);
            for i = 1:length(flds)
                fld=flds{i};
                if ~ismember(fld,Oflds)
                    Oflds{end+1,1}=fld;
                    Opts{fld}=S{fld};
                end
            end
        else
            bVal=true;
            S=dict(true,'fld',S);
            flds={'fld'};
        end
        m=strrep(chara,'\','');
        for i = 1:length(flds)
            fld=flds{i};

            if ischar(S{fld})

                % HANDLE VARIABLES LOCAL TO CONFIG FILE
                if contains(S{fld},m)
                    out=Str.RE.match(S{fld},[chara '[a-zA-Z]+[a-zA-Z_0-9]*']);
                    var=out(length(m)+1:end);

                    isfld=isfield(S,var);
                    if isfld
                        match=Str.RE.match(S{var},'@\{.*\}');
                    end

                    if isfld && ~isempty(match)
                        val=strrep(match,'@{',['@' var '{']);
                        S{fld}=strrep(S{fld},out,val);
                    elseif isfld
                        S{fld}=strrep(S{fld},out,S{var});
                    end
                end

                % GET CALLER VARS
                if contains(S{fld},'@')
                    out=Str.RE.match(S{fld},['@[a-zA-Z]+[a-zA-Z_0-9]*']);
                    out=out(2:end);
                    if ~ismember(out,callerVars)
                        callerVars=[callerVars; out];
                    end
                end

            elseif isa(S{fld},'dict')
                S{fld}=Cfg.meta_eval_meta_rec(SAll, S{fld},Opts,chara,callerVars);
            end
        end
        if bVal
            S=S{'fld'};
        end

    end
    function [D,R]=merge_fun(D,R)
        dFlds=fieldnames(D);
        rFlds=fieldnames(R);
        flds=unique([dFlds; rFlds]);
        for i = 1:length(flds)
            fld=flds{i};
            if ~ismember(fld,dFlds)
                D{fld}='@DEFAULT';
            elseif ~ismember(fld,rFlds);
                R{fld}=D{fld};
            elseif isa(D{fld},'dict') && isa(R{fld},'dict')
                [R{fld},D{fld}]=Cfg.merge_fun(R{fld},D{fld});
            end
        end
    end
    function Opts=rep_rec(Opts,str,rep)
        flds=fieldnames(Opts);
        for i = 1:length(flds)
            fld=flds{i};
            if ischar(Opts.(fld))
                Opts.(fld)=strrep(Opts.(fld),str,rep);
            elseif isa(Opts.(fld),'dict');
                Opts=Cfg.rep_rec(Opts.(fld),str,rep);
            end
        end
    end
