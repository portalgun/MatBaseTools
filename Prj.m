classdef Prj < handle
methods(Static)
    function [name,dire]=name(file,layers)
        if ~exist('layers','var') || isempty(layers)
            layers=1;
        end
        bPwd=false;
        if ~exist('file','var') || isempty(file)
            s=dbstack;
            if numel(s) > layers
                s=s(layers+1).name;
                s=strsplit(s,'.');
                file=which(s{1});
            else
                bPwd=true;
                file=[pwd filesep];
            end
        end
        [name,dire]=Prj.name_(file);
        if isempty(name) && ~bPwd
            file=[pwd filesep];
            [name,dire]=Prj.name_(file);
        end
    end
    function name=namePath()
        file=[pwd filesep];
        Prj.name(file);
    end
end
methods(Static, Access=private)
    function [name,dire]=name_(file)
        name=[];
        dire=Fil.parts(file);
        while ~isempty(dire)
            files=Dir.files(dire);
            dires=Dir.files(dire);
            if ismember('.px',files) || ismember('.git',dires)
                name=Dir.parentName([dire '.']);
                return
            end

            dire=Dir.parent(dire);
        end
    end
end
end
