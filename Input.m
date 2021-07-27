classdef Input < handle
% evaluate and do not add to history
%com.mathworks.mlservices.MLExecuteServices.consoleEval('')
methods(Static)
    function out = read(str,varargin)
        cmd=[ 'input(''' str ''',''' varargin{:} ''')'];
        cmd
        com.mathworks.mlservices.MLExecuteServices.consoleEval(cmd);
    end
    function out = yn(question)
        while true
            resp=input([question ' (y/n): '],'s');
            switch Input.valYN(resp)
                case 1
                    out=1;
                    break
                case 0
                    out=0;
                    break
                otherwise
                    disp('Invalid response.')
            end
        end
    end
    function out = char(chars,text,bAllowEsc);
        if ~exist('bAllowEsc','var') || isempty(bAllowEsc)
            bAllowEsc=0;
        end
        while true
            resp=input([text ': '],'s');
            if bAllowEsc && isempty(resp)
                out=[];
                return
            end
            if ~ismember(resp,chars)
                disp('Invalid response.')
                continue
            end
            out=resp;
            break
        end
    end
    function out = range(maxNum, bAllowEsc);
        if ~exist('bAllowEsc','var') || isempty(bAllowEsc)
            bAllowEsc=0;
        end
        if numel(maxNum) > 1
            error('Takes a max value not range/vector');
        end
        while true
            resp=input(['Select a value between 1 & ' num2str(maxNum) ': '],'s');
            if bAllowEsc && isempty(resp)
                out=[];
                return
            end
            inv=Input.valRange(resp,1:maxNum);
            if ~isempty(inv)
                disp('Invalid response.')
                continue
            end
            out=str2double(resp);
            break
        end
    end
    function [out,ind,exitflag] = select(list,bClear)
        if ~exist('bClear','var') || isempty(bClear)
            bClear=0;
        end


        intxt=['Please select an element (1-' num2str(length(list)) '): ' newline];
        errtxt=[newline 'Invalid response.' newline];

        str=cell(length(list),1);
        for i = 1:length(list)
            str{i}=[num2str(i) ' ' list{i}];
        end
        str=join(str,newline);
        str=[str{1} newline];
        fprintf(str);
        n=length(str);

        exitflag=0;
        while true
            resp=input(intxt,'s');
            n=n+length(resp)+ 1 + length(intxt);
            idxInvalid=Input.valRange(resp,1:length(list));
            if isempty(resp)
                exitflag=1;
                return
            elseif isempty(idxInvalid)
                ind=str2double(resp);
                out=list{ind};
                break
            else
                n=n+length(errtxt);
                fprintf(errtxt);
            end
        end
        if bClear
            bk=repmat('\b',1,n);
            fprintf(bk);
        end
    end
    function [out,ind,EXITFLAG] = selectMult(list,strin,bDuplicates)
        %function [out,ind] = basicSelectMult(list)
        bNumPrint=0;
        EXITFLAG=0;
        if isnumeric(list)
            if all(list==1:length(list))
                bNumPrint=1;
            end
            list=strsplit(num2str(list));
        end
        if ~exist('strin','var') || isempty(strin)
            strin='elements';
        end
        if ~exist('bDuplicates','var') || isempty(bDuplicates)
            bDuplicates=0;
        end

        if ~exist('list','var') || isempty(list)
            list={'TEST1', 'TEST2', 'TEST3','TEST4','TEST5'};
        end

        for i = 1:length(list)
            if bNumPrint
                disp(num2str(i));
            else
                disp([num2str(i) ' ' list{i}]);
            end
        end

        while true
            resp=input(['Please select ' strin  ' (1-' num2str(length(list)) ') with space separation: '],'s');
            if isempty('resp')
                EXITFLAG=1;
            end
            [resp,exitflag]=Input.expandRangeStr(resp);
            if exitflag==1
                disp('Invalid response.')
                continue
            end
            for i = 1:length(resp)
                idxInvalid{i}=Input.valRange(resp{i},1:length(list));
            end
            I=cellfun(@isempty,idxInvalid);
            if all(I)
                for i = 1:length(resp)
                    ind(i)=str2double(resp(i));
                    out{i}=list{ind(i)};
                end
                if ~bDuplicates
                    ind=unique(ind);
                    out=out(ind);
                end
                return
            else
                disp('Invalid response.')
            end
        end
    end


end
methods(Static, Hidden)
    function Out = valYN(response)
        %simple function to handle input yes no responses
        if strcmp(response,'y') || strcmp(response,'Y') || strcmp(response,'Yes') || strcmp(response,'yes')  || strcmp(response,'YES') || strcmp(response,'1')
            Out=1;
        elseif strcmp(response,'n') || strcmp(response,'N') || strcmp(response,'No') || strcmp(response,'no') || strcmp(response,'NO') || strcmp(response,'0')
            Out=0;
        elseif strcmp(response,'')
            Out=2;
        else
            Out=-1;
        end
    end
    function [idxInvalid] = valChars(response,validChars)

        if size(validChars,1)==1
            validChars=cellstr(validChars');
        else
            validChars=cellstr(validChars);
        end
        responseChars=cellstr(response');
        idxInvalid=find(~ismember(responseChars,validChars));
    end
    function [idxInvalid] = valRange(response,validRange)

        idxInvalid=Input.valChars(response,num2str(0:9));
        if ~isempty(idxInvalid)
            return
        end

        if isnumeric(validRange)
            validRange=num2str(validRange);
            if size(validRange,1)==1 && size(validRange,2)>1
            validRange=strsplit(validRange)';
            end
        else
            validRange=validRange(:);
        end

        vals=strsplit(response); %CONVERT spacingVals INTO CELL
        vals=vals(~cellfun('isempty',vals));
        if size(vals,1)==1
            vals=vals';
        end
        idxInvalid=find(~ismember(vals,validRange));
    end
end
methods(Static, Access=private)
    function [str,exitflag]=expandRangeStr(str)
        if ~iscell(str) && contains('str',' ')
            str=strsplit(str);
        end
        if ~iscell(str)
            str={str};
        end
        exitflag=0;
        i=0;
        while true
            i=i+1;
            if i > length(str)
                break
            end

            R=[];
            if ismember(':',str{i})
                r=strsplit(str{i},':');
                if length(r)>3
                    exitflag=1;
                    break
                end
                for j = 1:length(r)
                    R(j)=str2double(r{j});
                end
            end
            if ~isempty(R) && length(R)==3
                vals=colon(R(1),R(2),R(3));
            elseif ~isempty(R) && length(R)==2
                vals=colon(R(1),R(2));
            else
                continue
            end
            vals=num2str(vals);
            vals=strsplit(vals);
            if i == 1 && length(str)>1
                str={            vals{:} str{i+1:end}};
            elseif i==1
                str={            vals{:}              };
            elseif i == length(str)
                str={str{1:i-1} vals{:}              };
            else
                str={str{1:i-1} vals{:} str{i+1:end}};
            end
            i=i+length(vals)-1;
        end
    end




end
end
