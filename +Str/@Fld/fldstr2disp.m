function [str] = fldstr2disp(str,f)

if ~exist('f','var')==1 || isempty(f)
    %get float length
    f=0;
    for i = 1:length(str)
        spl=strsplit(str{i},'_');
        if length(spl) >= 2 && length(spl{2}) > f
            f=length(spl{2});
        end
    end
end


for i = 1:length(str)
    %replace chars
    str{i}=strrep(num2str(str{i}),'n','-');
    str{i}=strrep(str{i},'_','.');
    if str{i}(1)~='-'
        str{i}=strcat('+',str{i});
    end

    spl=strsplit(str{i},'.');
    %apply float
    if length(spl) >= 2
        fdiff=f-length(spl{2});
        if fdiff > 0
            zers=num2str(zeros(fdiff,1));
            str{i}=strcat(str{i},zers);
        end
    end

    %apply leading spaces
end

leadsp=0;
for i = 1:length(str)
    spl=strsplit(str{i},'.');
    if length(spl{1}) > leadsp
        leadsp=length(spl{1});
    end
end

for i = 1:length(str)
    spl=strsplit(str{i},'.');
    lzdiff=leadsp-length(spl{1});
    if lzdiff > 0
        zers=repmat(' ',1,lzdiff);
        str{i}=strcat(zers,str{i});
    end
end
