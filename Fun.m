classdef Fun < handle
methods(Static)
    function out = is(in)
        w=which(in);
        [~,~,ext]=fileparts(w);
        out=ismember(exist(in),[2,5]) && ~isempty(w) && ~strcmp(ext,'.mat');
    end
    function listBuiltin()
        sad = dir( fullfile( matlabroot, 'toolbox', 'matlab', '**', '*.m' ) );
        %%
        for d = reshape( sad, 1,[] )
            if d.bytes <= 4096
                ffs = fullfile( d.folder, d.name );
                chr = fileread( ffs );
                if contains( chr, 'Built-in function', 'IgnoreCase',true )
                    fprintf( '%s\n', d.name );
                end
            end
        end
    end

    function qhelp(functionStr)
    % XXX NOTE LIB
        hfig = figure('Name'       ,['Help: ' functionStr],...
                    'Toolbar'    ,'none',...
                    'Menubar'    ,'none',...
                    'NumberTitle','off');
        uicontrol('Parent'             ,hfig,...
                'Style'              ,'edit',...
                'String'             ,help(functionStr),...
                'HorizontalAlignment','left',...
                'Units'              ,'normalized',...
                'Position'           ,[0 0 1 1],...
                'Max'                ,2,...
                'Enable'             ,'inactive')
    end
    function str = repeat(rep,fnc,inputs)
        if ischar(inputs)
            inputs={inputs};
        end
        assert(iscell(inputs),'Inputs need to be in string or cellstring format.');
        %assert(isstring(inputs),'Function need to be a string')

        str1=repmat([fnc '(' ],1,rep);
        str1=[str1 inputs{1}];
        if length(inputs)>1
            str2=join(inputs(2:end),',');
            str2=str2{1};
            str2=[',' str2 ')'];
            str2=repmat(str2,1,rep);
        else
            str2=repmat(')',1,rep);
        end
        str=[str1 str2];
    end
    function getStdDeps()
        % XXX TODO
    end
    function expFcnListAll=getMissingDeps(prjDir,fcnName,bRecursive,bLong)
        if ~exist('bLong','var')
            bLong=[];
        end
        if ~exist('bRecursive','var')
            bRecursive=[];
        end
        [fcnListAll,expFcnListAll] = getNonStdDeps(fcnName,bRecursive,bLong);
        expFcnListAll{contains(expFcnListAll,directory)}=[];
        if bLong==0
            b=cellfun(@(x) strsplit(x,'/'),expFcnListAll,'UniformOutput',false);
            expFcnListAll=cellfun(@(x) x{end},b,'UniformOutput',false);
            b=cellfun(@(x) strsplit(x,'.'),expFcnListAll,'UniformOutput',false);
            expFcnListAll=cellfun(@(x) x{1},b,'UniformOutput',false);
        end
    end
    function [fcnListAll,expFcnListAll] = getNonStdDeps(fcnName,bRecursive,bLong)
        if ~exist('bLong','var') || isempty(bLong)
            bLong=0;
        end
        if ~exist('bRecursive','var') || isempty(bRecursive)
            bRecursive=0;
        elseif bRecursive
            disp('This may take a while')
            disp('Warning: if there is a interfunction recursion - this may never end')
            disp('         use the bLoop flag if you suspect this.')
        end
        global SEEN
        SEEN={''};
        [fcnListAll]=Fun.nonStdDeps_(fcnName,bLong,bRecursive,0,0);
        if bRecursive
            expFcnListAll=unique(Fun.expandCellTree_(fcnListAll));
        else
            expFcnListAll=[];
        end
        fcnListAll=transpose(fcnListAll);
    end
    % --------------------------------------------------------------------
    function fcnlist=getParents(fcnName,varargin)
        %list functions that depend on the given function, with current directory
        %when varargin{1}=1, search recursively from home folder
        %when varargin{1}=2, search server home code directory recursivley
        %NOTE may need coreutils (gnu) installed and added to SHELL path to work

        if length(varargin)==0
            old=pwd;
        elseif varargin{1}==1
            old=cd('~');
        elseif varargin{1}==2
            old=('/Users/Shared/Matlab/BurgeLabToolbox');
        end

        command=['grep -r "' fcnName '(" * | awk ''{print $1}'' | cut -d : -f1 | grep -v "/' fcnName '.m"'];
        [~,fcnlist] = system(command);

        cd(old);
    end
end
methods(Static, Access=private)
    function fcnListAll = nonStdDeps_(fcnName,bLong,bRecursive,bLoop,layer)
    %function [fcnListAll,expFcnListAll] = lsNonStdDeps(fcnName,bLong,bRecursive,bLoop,)
    % list dependencies (functions called) of a function
    % examplecall
    %        [List, expList]=lsNonStdDeps('loadLRSIimage',0,1)
    %
    % fcnName - name of function in quotation without '.m'
    % bLong   - 1 -> full filename
    %           0 -> shortname (default)
    % bRecursive - Recursively list dependencies
    % layer - used for recursion, don't set
    % seen  - used for recursion, don't set
    %
    % fcnListAll - function dependencies listed
    %        if bRecursive == 1, listed in tree structure
    %           left column is highest layer of dependency
    %           right column contains the dependencies of dependencies
    %           follow recursively
    % expFcnListAll - fcnListAll, but entire tree listed in one column, with duplicates removed
    % --------------------------------------------------------------------
        global SEEN

        try
            fcnList = matlab.codetools.requiredFilesAndProducts(fcnName,'toponly');
            disp(fcnName)
        catch
            disp(['Error with ' fcnName]);
            fcnListAll='';
            return
        end
        listIndex = strcmp(path,fcnList);
        fcnList = fcnList(setdiff(1:numel(fcnList),listIndex));
        if bRecursive && bLoop
            fcnList(ismember(fcnList,SEEN))=[];
        end
        if isempty(fcnList)
            fcnListAll='';
            return
        end

        if ~bLong
            b=cellfun(@(x) strsplit(x,'/'),fcnList,'UniformOutput',false);
            fcnList=cellfun(@(x) x{end},b,'UniformOutput',false);
            b=cellfun(@(x) strsplit(x,'.'),fcnList,'UniformOutput',false);
            fcnList=cellfun(@(x) x{1},b,'UniformOutput',false);
        end

        fcnList(ismember(fcnList,{fcnName}))=[];
        if bRecursive
            %fprintf('.');
            layer=layer+1;
            fcnListAll=cell(length(fcnList),2);
            for i =1:length(fcnList)
                if ismember(fcnList{i},SEEN);
                    continue
                end
                SEEN{end+1,1}=fcnList{i};
                fcnListAll{i,1}=fcnList{i};
                fcnListAll{i,2}=Fun.nonStdDeps_(fcnList{i},0,1,bLoop,layer);
            end
        else
            fcnListAll=fcnList;
        end
    end
    function [List] = expandCellTree_(cellTree,List)
        if exist('List','var')~=1
            List=[];
        end
        List=[List; cellTree(:,1)];
        for i = 1:size(cellTree,1)
            [List]=Fun.expandCellTree_(cellTree{i,2},List);
        end
    end
end
end
