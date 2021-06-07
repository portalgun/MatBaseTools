function out = are(in)
if ~iscell(in) || isemptyall(in)
    out=0;
    return
end
out=all(cellfun(@(x) ischar(x)| isempty(x),in),'all');
