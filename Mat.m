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
                release=1;
            case 'b'
                release=2;
            case 'c'
                release=3;
            case 'd'
                release=4;
        end
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
    function file=get_history_xml()
        dire=prefdir;
        mHistX=[dire 'History.xml'];
        %com.mathworks.util.FileUtils.getPreferencesDirectory
    end
    function file=get_bak_history_xml()
        dire=prefdir;
        mHistX=[dire 'History.bak'];
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
        file=Mat.getHistory();
        if Mat.isgui && isunix()
            cmd=['tac ' file ' | sed ''/<command .*/ {s///; :loop; n; b loop}'' | tac > ' file];
            unix(cmd);
        elseif ~isunix()
            error('OS not yet handled');
        elseif ~Mat.isgui
            error('Non gui not handled yet');
        end
        Mat.historyReload();
    end
%%
    function historyRead()
        file=Mat.getHistory();
        history = string(fileread(file));
    end
    function addHistory(cmd)
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
