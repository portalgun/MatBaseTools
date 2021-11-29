classdef Mat < handle
methods(Static)
    function out=isgui()
        out=usejava('desktop');
    end

    function [year, release, full] = version()
        % function [year, release, full] = Mat.version()
        % returns current matlab version
        %
        % example call:
        %    Mat.version
        %
        % Outputs:
        %    year    - matlab version year as number
        %    release - year iteration number (a=1, b=2 ...)
        %    full    - full version (eg. '2017a')

        verInfo = ver;
        full=verInfo(1).Release(3:end-1);
        year = str2num(verInfo(1).Release(3:end-2));
        release = verInfo(1).Release(end-1);
        switch release
            case 'a'
                release=0.1;
            case 'b'
                release=0.2;
            case 'c'
                release=0.3;
            case 'd'
                release=0.4;
        end
    end
    function out=timeout(secs,failFun,fun,varargin)
        if isempty(failFun)
            failFun='com.mathworks.mde.cmdwin.CmdWinMLIF.getInstance().processKeyFromC(2,67,''C'')';
        end
        t = timer('TimerFcn', ...
                  failFun, ...
                  'StartDelay',secs);
        start(t);
        out=feval(fun,varargin{:});
    end
    function list=featureList()
        setenv('MWE_INSTALL','1'); list = feature('list'); setenv('MWE_INSTALL');
        list=sort({list.name}');
    end
    function compile_feature()
        dire=Dir.parent(mfilename('fullpath'));
        fname=[dire 'feature_list.cpp'];
        if isunix
            mex(fname,['-L',matlabroot,'/bin/',computer('arch')],'-lmwservices');
        else
            mex(fname,'-llibmwservices');
        end
    end
    function [X]=get_editing()
        % X
        %  Filename
        %  Opened
        %  Langauge
        %  Text
        %  Selection
        %  SelectedText
        %  Modified
        %  Editable
        X = matlab.desktop.editor.getAll;
        files=transpose({X.Filename});
    end
    function X=get_editing_active()
        X=matlab.desktop.editor.getActive();
    end
    function files=getEditing()
        X=Mat.get_editing();
        files=transpose({X.Filename});
    end
    function file=getEditingActive()
        file=matlab.desktop.editor.getActiveFilename();
    end
    function []=closeEditing(ind)
        X=Mat.get_editing();
        if isempty(X)
            return
        end
        if ~exist('ind','var') || isempty(ind)
            ind=1;
        end

        close(X(ind));
    end
    function closeEditingAll()
        X = matlab.desktop.editor.getAll;
        close(X);
    end

    function evalinBaseQuiet(cmd)
        if ~endsWith(cmd,';')
            cmd=[cmd ';'];
        end
        com.mathworks.mlservices.MLExecuteServices.consoleEval(cmd);
    end
    function evalinBase(cmd)
        if ~endsWith(cmd,';')
            cmd=[cmd ';'];
        end
        com.mathworks.mlservices.MLExecuteServices.executeCommand(cmd);
    end
%% HISTORY get
    function file=getHistory()
        if Mat.isgui()
            file=Mat.get_history_xml();
        else
            file=Mat.get_history_m();
        end
    end
    function file=getBakHistory()
        if Mat.isgui()
            file=Mat.get_bak_history_xml();
        else
            file=Mat.get_bak_history_m();
        end
    end
%% PRIV
    function file=get_history_m()
        mdir=Dir.parse(prefdir);
        file=[mdir 'history.m'];
    end
    function file=get_bak_history_m()
        mdir=Dir.parse(prefdir);
        file=[mdir 'history_m.bak'];
    end
    function fname=get_history_xml()
        dire=Dir.parse(prefdir);
        fname=[dire 'History.xml'];
        %com.mathworks.util.FileUtils.getPreferencesDirectory
    end
    function fname=get_bak_history_xml()
        dire=prefdir;
        fname=[dire 'History.bak'];
        %com.mathworks.util.FileUtils.getPreferencesDirectory
    end
    function get_history_bak()
        mHistB=[dire 'History.bak'];
    end
%%
    function historyReload()
        file=java.io.File(Mat.getHistory());
        com.mathworks.mde.cmdhist.AltHistory.load(file,false);
    end
    function out=rmLastHistory()
        Mat.saveHistory;
        file=Mat.getHistory();
        lines=Fil.cell(file);
        ind=find(startsWith(lines,"<command "),1,'last');
        lines(ind)=[];
        Fil.rewrite(file,lines);
        Mat.historyReload();
    end
    function out=replaceLastHistory(cmd)
        Mat.saveHistory;
        file=Mat.getHistory();
        lines=Fil.cell(file);
        ind=find(startsWith(lines,"<command "),1,'last');
        lines(ind)=[];
        Fil.rewrite(file,lines);


        Mat.addHistory(cmd);
        Mat.historyReload();
    end
    function out=rmLastBatchHistory()
        Mat.saveHistory;
        file=Mat.getHistory();
        lines=Fil.cell(file);
        ind=find(startsWith(lines,"<command batch"),1,'last');

        match=Str.RE.match(lines{ind},'batch="[0-9]+"');
        num=num2str(Str.RE.match(match,'[0-9]+'));
        ind=find(contains(lines,[' batch="' num '"']));
        lines(ind)=[];
        Fil.rewrite(file,lines);
        Mat.historyReload;
    end
%%
    function historyRead()
        file=Mat.getHistory();
        history = string(fileread(file));
    end
    function addHistory(cmd)
        % XXX DOESN"T WORK
        com.mathworks.mlservices.MLCommandHistoryServices.add(cmd);
    end
    function out=getSessionHistory()
        out=com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory();
    end
    function out=getAllHistory()
        out=com.mathworks.mlservices.MLCommandHistoryServices.getAllHistory();
    end
    %function out=notify()
    %    % XXX
    %    out=com.mathworks.mlservices.MLCommandHistoryServices.notify();
    %end
    %function out=notifyAll()
    %    % XXX
    %    out=com.mathworks.mlservices.MLCommandHistoryServices.notifyAll();
    %end
    function out=rmAllHistory()
        com.mathworks.mlservices.MLCommandHistoryServices.removeAll();
        %com.mathworks.ide.cmdline.CommandHistory.deleteAllHistoryForDesktop();
    end
    function out=saveHistory()
        com.mathworks.mlservices.MLCommandHistoryServices.save();
    end
    function out=getInstHist()
        out=com.mathworks.mde.cmdhist.CmdHistory.getInstance();
    end
    function out=getRecalledHist()
        out=com.mathworks.mde.cmdhist.AltHistory.getRecalledCommands();
    end
    %function out=rmLastHistory(k)
    %    if ~exist('k','var') || isempty(k)
    %        k=1;
    %    end
    %    all=Mat.getAllHistory();
    %    %sess=Mat.getSessionHistory();
    %    %n=length(all)-length(sess)
    %    all=all(end-k);
    %    assignin('base','all',all)

    %    Mat.rmAllHistory();
    %    Mat.addHistory(all);



    %end
end
end
