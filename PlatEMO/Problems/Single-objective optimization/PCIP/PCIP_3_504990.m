classdef PCIP_3_504990 < PROBLEM
    % <single> <integer>
        properties
            conflictMarix_11 
            disturbMarix_11
            conflictMarix_01
            disturbMarix_01
            confoundMarix	% Optimal decision vector
            Node
            confligLinklistMarix
            PCI454_0
            fre454_pos
        end
        methods
            %% Default settings of the problem
            function Setting(obj)
                obj.M = 1;
                if isempty(obj.D); obj.D = 1613; end
                obj.lower    = zeros(1,obj.D);
                obj.upper    = ones(1, obj.D) * 1007;
                obj.encoding = ones(1,obj.D) * 2;
                %obj.conflictMarix = zeros(454); %2067*2067的0矩阵
                %obj.disturbMarix = zeros(454);
                %obj.confoundMarix = zeros(454);
                %数据读取
                obj.conflictMarix_11 = load("fre504990.mat").fre504990_con_11;%冲突矩阵
                obj.disturbMarix_11 = load("fre504990.mat").fre504990_dis_11;%干扰矩阵
                obj.conflictMarix_01 = load("fre504990.mat").fre504990_con_01;%冲突矩阵
                obj.disturbMarix_01 = load("fre504990.mat").fre504990_dis_01;%干扰矩阵
                %这里还需要修改
                obj.PCI1613_0 = load("PCI.mat").PCI504990_0; %获得504990频率的PCI
    
                obj.fre1613_pos = load("PCI.mat").fre1613_pos; %获得454的PCI序号，方便修改
                
                %链表实现以缩减稀疏矩阵的运算量
                obj.Node = struct('data', [], 'next', []);
                obj.confligLinklistMarix = repmat(obj.Node, 1, 1613);
                disp(max(obj.conflictMarix_01))
                for i = 1:1613 %头结点矩阵
                    disp(i)
                    newhead = obj.createLinkedList(i); %建立新节点
                    for j = 1:95570 %寻找所有连接节点——冲突不为0即连接
                        if obj.conflictMarix_01(i,j) ~= 0 
                            disp(55555)
                            obj.insertNode(newhead, obj.PCI1613_0(j));
                        end
                    end 
                    obj.confligLinklistMarix(i) = newhead; %赋值给对应的链表矩阵中
                end
                obj.traverseLinkedList(obj.confligLinklistMarix(1));
                disp("init finish!")
            end
            %% Calculate objective values
            function PopObj = CalObj(obj,PopDec)
                %myMod3Dec = mod(PopDec,3);
                disp("new turn")
                for k = 1:size(PopDec,1) %遍历每个种群
                    %开始计算冲突
                    myDec = PopDec(k,:);
                    sumconflig = 0;
                    sumdisturb = 0;
                   % sumconfound = 0;
                    for i = 1:454 %遍历修改表里面的PCI值
                        obj.PCI454(1,obj.fre454_pos(i)) = myDec(i);
                    end
                    for i = 1:454 %查找有没有重复的
                        for j = 1:14824
                            if myDec(i) == obj.PCI454(1,j)
                                sumconflig = sumconflig + obj.conflictMarix(i,j); 
                    %            sumconfound = sumconfound + obj.confoundMarix(i, j) + obj.confoundMarix(j, i);                
                            end
    %                         if obj.Fre(i) == obj.Fre(j)
    %                             if myMod3Dec(k,i) == myMod3Dec(k,j) 
    %                                 sumdisturb = sumdisturb + obj.disturbMarix(i,j) + obj.disturbMarix(j,i);
    %                             end
    %                         end
                        end
                    end
                    PopObj(k,:) = sumconflig;
                    %PopObj(k,2) = sumconfound;%sumconflig + sumdisturb + sumconfound;
                end
            end
    
            function head = createLinkedList(obj,data)
                head = obj.Node;
                head.data = data;
                head.next = [];
            end
    
            % 插入节点
            function head = insertNode(obj,head, data)
                newNode = obj.Node;
                newNode.data = data;
                newNode.next = head.next;
                head.next = newNode;
                head = newNode;
            end
            function traverseLinkedList(head)
                current = head;
                while ~isempty(current)
                    disp(current.data);
                    current = current.next;
                end
            end
        end
end