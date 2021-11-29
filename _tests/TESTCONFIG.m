
if strcmp(Sys.hostname,'BONICE')
    home='/home/dambam';
elseif ismac
    home='/homes/davwhite';
end


file=[ home '/Code/mat/projects/ConfigReader/testconfig'];
f=mfilename('fullpath');
[dire]=[fileparts(f) filesep];
%
%file=[dire 'testconfig1'];
%Options1=Cfg.read(file);

%file=[dire 'testconfig2'];
%Options2=Cfg.read(file);

%file=[home '/Documents/MATLAB/.px/etc/Px.config'];
%Options3=Cfg.readHost(file);

file=[home '/Documents/MATLAB/.px/etc/ENV.config'];
%Options4=Cfg.read(file);

file=[home '/Documents/MATLAB/.px/etc/ExpTrk.config'];
Options5=Cfg.read(file);

file=[home '/Documents/MATLAB/.px/etc/Imap.config'];
Options6=Cfg.read(file);
