function hh = sgtitle(varargin)
% SGTITLE  Title for a grid of subplots.
%   SGTITLE('text') adds text at the top of a grid of subplots.
%
%   SGTITLE('text','Property1',PropertyValue1,'Property2',PropertyValue2,...)
%   sets the values of the specified properties of the title.
%
%   SGTITLE(parent,...) adds the title to the container specified by parent.
%
%   H = SGTITLE(...) returns the handle to the text object used as the subplot grid title.
%
%   H = SGTITLE() returns the handle to the text object used as the current subplot grid title.
%
%   See also SUBPLOT.

%   Copyright 2018 The MathWorks, Inc.

    if nargin == 0
        parent = findParent();
        if(~isempty(parent))
            hh = getappdata(parent, 'SubplotGridTitle');
        else
            hh = gobjects(0);
        end
        return
    end
    
    nvIndex = 2;
    
    parent  = gobjects(0);
   
    if isa(varargin{1},'matlab.graphics.Graphics') && ...
            isa(varargin{1},'matlab.ui.container.CanvasContainer') && ...
            isvalid(varargin{1}) 
        % Parent is first arg
        if (nargin < 2) || rem(nargin,2) ~= 0 
            error(message('MATLAB:sgtitle:InvalidNumberOfInputs'))
        end
        
        % Text is second arg
        txt = varargin{2};
         
        % Check for parent as name/value pair
        if(nargin > 2)
            parent = findParentArg(varargin(3:end));
        end
        
        % Use first arg as parent if there is no parent in the name/value pair list
        if isempty(parent)
            parent = varargin{1};
        end
        
        nvIndex = 3;
    else
        % Text is first arg
        txt = varargin{1};      
        
        % Check for parent as name/value pair
        if(nargin > 2)
            parent = findParentArg(varargin(2:end));
        end
        
        if isempty(parent)
            % Check for existing parent container
            parent = findParent();
            if isempty(parent)
                parent = figure();
            end
        end
    end
    
    % Error if AutoResizeChildren is 'on'
    if isprop(parent,'AutoResizeChildren') && strcmp(parent.AutoResizeChildren,'on')
        error(message('MATLAB:sgtitle:AutoResizeChildren'))
    end

    h = createSubplotText(txt);
    
    % Capture the existing title on the parent
    oldTitle = getappdata(parent, 'SubplotTitle');
    
    if(nvIndex <= nargin)
        pvpairs = matlab.graphics.internal.convertStringToCharArgs(varargin(nvIndex:end));
        set(h, pvpairs{:});
    end

    if nargout > 0
        hh = h;
    end
    
     % Delete any existing title before parenting the new title
    if(~isempty(oldTitle))
        delete(oldTitle);
    end
    
    h.Parent = parent;
    h.setupAppData(h.Parent);

    subplotlayoutInvalid(h, [], h.Parent);    

end  
  
function parent = findParent
    parent = handle(get(groot, 'CurrentFigure'));
    if ~isempty(parent) && ~isempty(parent.CurrentAxes)
         parent = parent.CurrentAxes.Parent;
    end
end

function parent = findParentArg(nvpairs)
    parent = gobjects(0);
    parentIndex = 2*find(strcmpi('Parent', nvpairs(1:2:end-1)));
    if any(parentIndex)
        p = nvpairs{parentIndex(end)};
        if isa(p,'matlab.graphics.Graphics') && ...
            isa(p,'matlab.ui.container.CanvasContainer') && ...
            isvalid(p) 
            parent = p;
        end
    end
end

function t = createSubplotText(str) 
    t = matlab.graphics.illustration.subplot.Text();
    t.String = str;
end
