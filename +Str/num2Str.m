function str = num2Str(num)
    tmp=num2cell(num);
    str=cellfun(@(x) num2str(x),tmp,'UniformOutput',false);
end
