function Open(varargin);
    editor=Env.var('EDITOR');
    file=which(varargin{1});
    cmd=[editor ' ' file  ];
    system(cmd);
end
