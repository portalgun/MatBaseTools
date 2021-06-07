function out = dims(var)
% Returns the size of a variable as a string in the format '[ N x M x O ]'
% CREATED BY DAVID WHITE
out=num2str(size(var));
out=strrep(out,'  ',' x ');
out=['[ ' out ' ]'];
