function str= Num.toStr(num,n,bBracket,bSpace)
if islogical(num)
    num=double(num);
end
if isempty(num)
    str='';
    return
end
if exist('n','var') && ~isempty(n) && n~=0
    n=min(max(Num.nSigDec(num)),n);
    n={['%.' num2str(n) 'f ']};
else
    n={};
end
if size(num,2) > 1 & size(num,1) > 1
    s=char(strjoin(join(string(num),2),newline));
elseif size(num,1) > 1
    s=char(strjoin(string(num),newline));
else
    s=num2str(num,n{:});
end
str=regexprep(s,' +',',');
if exist('bSpace','var') && ~isempty(bSpace) && bSpace
    str=strrep(str,',',', ');
end

if exist('bBracket','var') && ~isempty(bBracket) && bBracket && numel(num) > 1
    str=['[ ' str ' ]'];
end
