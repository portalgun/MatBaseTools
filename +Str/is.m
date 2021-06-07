function out=is(in)
    out=ismember(in,Str.A());

    if ~exist('key','var') || isempty(key)
        return
    elseif strcmp(key,'all')
        out=all(out);
    else
        error(['Unhandled key: '  key ]);
    end

end

