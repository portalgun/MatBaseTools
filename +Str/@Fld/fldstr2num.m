function [nums] = fldstr2num(str)
if iscell(str)
    for i = 1:length(str)
        str{i}=strrep(num2str(str{i}),'p','');
        str{i}=strrep(num2str(str{i}),'n','-');
        str{i}=strrep(str{i},'_','.');
    end
else
    for i = 1:length(str)
        str=strrep(num2str(str),'p','');
        str=strrep(num2str(str),'n','-');
        str=strrep(str,'_','.');
    end
end
nums=str2double(str);
