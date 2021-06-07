function STR = split(str,chara)
% function STR = Split(str,chara)
%
%   example call
%      str='    abc   def gh ikl '
%      STR=Split(str)
%
%   Divides string (str) at a characters (chara) and returns the result as the output array STR.
%
%   str:    string
%   chara:  character to split at
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   STR:    cell where elements are substrings of str that were seperated by chara

if Mat.version >= 2017
    STR=split(str,chara)
    return
end
if ~exist('chara','var') || isempty(chara)
    chara = ' ';
end

%
ind=strfind(str,chara);
if isempty(ind)
    STR{1}=str;
    return
end

%INIT CELL
if strcmp(str(end),chara)
    STR=cell(length(ind)-1,1);
else
    STR=cell(length(ind)+1,1);
end

STR{1}=str(1:ind(1)-1)
for i = 2:length(ind)
    STR{i}=str(ind(i-1)+1:ind(i)-1);
end
if ~strcmp(str(end),chara)
    STR{end}=str(ind(end)+1:end);
end
STR(cellfun(@(x) isempty(x), STR))=[];
