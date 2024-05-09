classdef PSCF_30 < PROBLEM
% <multi> <binary> <large/none> <sparse/none>

%------------------------------- Reference --------------------------------

%------------------------------- Copyright --------------------------------
% Copyright (c) 2022 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------
    properties
        theta ;    % Sparsity of the Pareto set
        data;
        G;
    end
methods
        %% Default settings of the problem
        function Setting(obj)
            if isempty(obj.M); obj.M = 3; end
            %攻击线路
            if isempty(obj.D); obj.D = 41; end
            %整数编码，攻击线路的编号1-41
            obj.encoding = 4 + zeros(1,obj.D);
            obj.data = loadcase(case30);
            %利用matlab图论工具包，构建图
            obj.G = digraph();
            obj.G = addnode(obj.G, 30); 
            for i= 1:length(obj.data.branch)
                obj.G = addedge(obj.G, obj.data.branch(i,1), obj.data.branch(i, 2));
            end
        end
        %% Calculate objective values
        function PopObj = CalObj(obj,PopDec)
            data = obj.data;
            PD = 3; %real power demand (MW)
            QD = 4; %Reactive power demand (MVA)
            mpopt = mpoption('pf.alg', 'NR', 'pf.nr.max_it', 10,'verbose',0,'out.all',0);
            PopObj = zeros(size(PopDec,1),3);
            % nl - Number of lines in the system,线路的条数
            nl = length(data.branch);
            F_BUS = 1; % "from" bus number,首端节点在branch中所在的列数
            T_BUS = 2; % "To" bus number，末端节点在branch中所在的列数
            % initial branch status, 1 = in-service, 0 = out-of-service
            BR_STATUS = 11;%branch中判断线路是否在工作状态所在的列数

            betweenness_centrality = centrality(obj.G, 'betweenness'); %计算所有节点的介数
            for i = 1 : size(PopDec,1)            
                Is_Converged = 0;%判断是否收敛
                BRANCH_FAILURES  = find(PopDec(i,:) == 1);%初始失效线路的编号
                FROM_NODES = data.branch(BRANCH_FAILURES,F_BUS);%初始失效线路首端节点编号
                TO_NODES = data.branch(BRANCH_FAILURES,T_BUS);%初始失效线路末端节点编号
                Failure_Branch = [];
                Node_From = [];
                Node_To = [];
                II = 0;
                %判断级联失效是否收敛
                while ~all(Is_Converged)
                    mpc = data;
                    BRANCH_FAILURES = [BRANCH_FAILURES,Failure_Branch'];
                    FROM_NODES = [FROM_NODES;Node_From];
                    TO_NODES = [TO_NODES;Node_To];
                    mpc.branch(BRANCH_FAILURES,BR_STATUS) = 0;
                    %前面的没问题
                    [P_shed,P_served,Is_Converged,Branch_temp,MPC] = CascadingFramework(mpc,mpopt);
                    if isempty(Branch_temp)
                        Failure_Branch = [];
                        Node_From = [];
                        Node_To = [];
                    else
                        Failure_Branch = find(mpc.branch(:,F_BUS) == Branch_temp(2) & mpc.branch(:,T_BUS) == Branch_temp(3));
                        Node_From = Branch_temp(2);
                        Node_To = Branch_temp(3);
                    end
                    II = II + 1;
                    if II > nl
                        disp('Iterations exceeded nl!')
                        break
                    end
                end
                mycost = 0;
                %计算节点的度以及边的介数，计算攻击成本
                for k=1:size(FROM_NODES,1)
                    fromNode = FROM_NODES(k);
                    toNode = TO_NODES(k);
                    total_degree_node1 = outdegree(obj.G, fromNode);
                    total_degree_node2 = indegree(obj.G, toNode);
                    nodebet1 = betweenness_centrality(fromNode);
                    nodebet2 = betweenness_centrality(toNode);
                    mycost = mycost + 0.5*total_degree_node1*total_degree_node2 + 0.5*(nodebet1+nodebet2 );
                end
                %统计导纳值，以线路的导纳值作为攻击成本
                % for k=1:nl
                %     %branch begin
                %     I = data.branch(k,1);
                %     %branch end
                %     J = data.branch(k,2);
                %     if (J~=0)&&(I~=0)
                %         % Column 3 is resistance and column 4 is reactance
                %         % branch_impedances Zt,Calculate the impedance Z
                %         Zt=data.branch(k,3)+1i*data.branch(k,4);
                %         Yt=1/Zt;
                %         total_cost(k) = real(Yt); 
                %     end
                % end
                % disp(BRANCH_FAILURES)
                % cost = sum(total_cost(BRANCH_FAILURES));
                % PopObj(i,1)=cost/sum(total_cost);
                %PopDec()
                PopObj(i,1)=mycost;
                PopObj(i,2)=sum(P_served)/sum(data.bus(:,3));
                PopObj(i,3)=sum(PopDec(i,:))/41;
            end       
        end
        
        %% Generate a point for hypervolume calculation
        function R = GetOptimum(obj,~)
            R=[1,1,1];
        end
         
    end
end