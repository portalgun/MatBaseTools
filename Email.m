classdef Email < handle
methods(Static)
    function [] = sendSms(msg,subject,to,from,smApp,tmpDir)
        if nargin < 6 || isempty(tmpDir)
            tmpDir='/tmp/';
        end
        if nargin < 5 || isempty(smApp)
            smApp=Env.var('SM_NOTIFY');
        end
        if nargin < 4 || isempty(from);
            from=Env.var('FROM_NOTIFY');
        end
        if nargin < 3 || isempty(to);
            to=Env.var('SMS_NOTIFY');
        end

        frmt=[...
                 'Subject: %s \n' ...
                 'From: %s \n' ...
                 'To: %s \n' ...
                 'Content-Type: text/plain; charset="utf8"\n\n' ...
        ];
        header=Vec.col(strsplit(sprintf(frmt,subject,from,to), '\n'));

        if ~iscell(msg)
            msg=strrep(msg,'\n',newline);
            msg=Vec.col(strsplit(msg,newline));
        else
            msg=Vec.col(msg);
        end

        MSG=[header; msg];

        file=[tmpDir 'matEmail.tmp'];
        Fil.rewrite(file,MSG);

        cmd= [smApp ' ' from  ' < ' file ' ' ];
        status=system(cmd);
        if status==0
            display('SMS sent');
        else
            display('SMS NOT sent');
        end
    end
end
end
