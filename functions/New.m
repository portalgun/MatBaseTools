function New(varargin);
    editor=Env.var('EDITOR');
    file=varargin{1}
    if hasPx
        base=[Env.var('PX_CUR_WRK') Env.var('PX_CUR_PRJ_NAME') filesep];
    end
    Fil.touch(varargin{1});
    file=which(varargin{1});
    cmd=[editor ' ' file  ];
    system(cmd);
end
