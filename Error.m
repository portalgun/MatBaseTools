classdef Error < handle
methods(Static)
    function soft(msg)
        error(msg);
    end
    function resetDefaults()
        warning('on','verbose');
        warning('on','backtrace');
    end
    function warnSoft(varargin)
        bME=false;
        bID=false;
        bMsg=false;
        % ARG 1
        if isa(varargin{1},'MException')
            bME=true;
            ME=varargin{1};
        elseif nargin == 1 && ischar(varargin{1})
            bMsg=true;
            msg=varargin{1};
        end
        % ARG 2
        if nargin > 1
            if isa(varargin{2},'MException')
                bME=true;
                ME=varargin{2};
            elseif bME && ischar(varargin{2})
                bMsg=true;
                msg=varargn{2};
            elseif bMsg && ischar(varargin{2})
                bID=true;
                warID=varargin{2};
            end
            if nargin > 2
                if isa(varargin{3},'MException')
                    bME=true;
                    ME=varargin{3};
                else
                    bID=true;
                    warID=varargin{3};
                end
            end
        end

        out=warning('query');
        if strcmp(out(1).state,'off');
            return
        end
        out=warning('query','verbose');
        vState=out.state;
        out=warning('query','backtrace');
        bState=out.state;

        cl=onCleanup(@() Error.cleanup_fun(vState,bState));
        warning('off','verbose');
        warning('off','backtrace');

        if bME && bID && bMsg
            msg=[msg newline '    ' ME.message];
            warning(warnID,msg);
        elseif bME && bMsg
            msg=[msg newline '    ' ME.message];
            warning(ME.identifier,ME.message);
        elseif bME
            warning(ME.identifier,ME.message);
        elseif bID && bMsg
            warning(warnID,msg);
        elseif bMsg
            warning(msg);
        end
    end
end
methods(Static, Hidden)
    function test_warnSoft()
        Error.warnSoft('test');
    end

end
methods(Static,Access=private)
    function cleanup_fun(vState,bState)
        warning(vState,'verbose');
        warning(bState,'backtrace');
    end
end
end
