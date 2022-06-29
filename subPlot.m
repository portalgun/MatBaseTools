
function H=subPlot(varargin)

    if length(varargin{1}) == 2
        r=varargin{1}(1);
        c=varargin{1}(2);
        varargin(1)=[];
    else
        r=varargin{1};
        c=varargin{2};
        varargin(2)=[];
        varargin(1)=[];
    end
    if length(varargin{1}) == 2
        h=varargin{1}(1);
        w=varargin{1}(2);
        varargin(1)=[];
    else
        h=varargin{1};
        w=varargin{2};
        varargin(2)=[];
        varargin(1)=[];
    end
    ind=sub2ind([c,r],w,h);
    HH=subplot(r,c,ind,varargin{:});
    if nargout > 0
        H=HH;
    end
end
