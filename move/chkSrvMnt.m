function [exitflag]=chkSrvMnt()
% function [exitflag]=chkSrvMnt()
% CHECK IF SERVER IS MOUNTED
% CREATED BY DAVID WHITE

while true
    directory=Env.var('DATA','SRV');
    subdirs=dir(directory);
    if length(subdirs)<=2
        bSubDirs=0;
    else
        bSubDirs=1;
    end

    if ~any(exist(directory,'file')==7) || bSubDirs==0
        mountServer;
        clear %reloads directory cache
    end

    exitflag=0;
    directory=Env.var('DATA','SRV');
    subdirs=dir(directory);
    if length(subdirs)<=2
        bSubDirs=0;
    else
        bSubDirs=1;
    end

    if ~any(exist(directory,'file')==7) || bSubDirs==0
        disp('Server is not mounted. Mount, then press enter to try again.');
        resp=input('Enter ''exit'' to continue without: ','s');
        if strcmp(resp,'exit')
            exitflag=1;
            return
        end
    else
        return
    end
end
