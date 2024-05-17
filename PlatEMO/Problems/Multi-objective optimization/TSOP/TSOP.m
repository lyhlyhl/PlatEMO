classdef TSOP < PROBLEM
% <multi> <binary> <constrained>
% Pressure vessal problem

%------------------------------- Reference --------------------------------

%------------------------------- Copyright --------------------------------
% Copyright (c) 2023 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

%算法逻辑说明：
%首先，决策变量->76*3606
%76为76条路，3606为od对数量
%
    properties
        od %od矩阵
        fft %空闲通过时间
        capacity %车道容量
        G %路网
        alpha = 0.15 %BRP函数超参数
        beta = 4.0
    end
    methods
        function Setting(obj)
            %算法部分
            obj.M = 2; %两个目标
            obj.D = 3606 * 76;   %针对每一个OD对缩小100倍,以及每一条路
            obj.encoding = 4 + zeros(1,obj.D);   %决策变量编码方式为2进制
                                                 %分别代表选择哪些边
            % 二进制编码不需要上下界

            %读取网络的相关数据
            obj.od = load("OD.mat").od;
            obj.fft = load("NET.mat").fft;
            obj.capacity = load("NET.mat").capacity;
            edge = load("NET.mat").edge;
            %图论相关的
            obj.G = digraph(edge~=0); %构建有向图
            edgefft = zeros(1,76); %初始化两个边属性分别是FFT和capacity
            edgecapacity = zeros(1,76);
            for i = 1:76 %循环更新边属性
                edgeID = findedge(obj.G, obj.fft(i,1), obj.fft(i,2));
                edgefft(edgeID)=obj.fft(i,3); %存储空闲通过时间
                edgecapacity(edgeID) = round(obj.capacity(i,3)/100); %将容量缩小一百倍，并且4舍5入，采用round函数
            end
            obj.G.Edges.fft = edgefft'; %edge是一个列向量，后面的必须转置。'作用是转置
            obj.G.Edges.capacity = edgecapacity'; 
            obj.G.Edges.flow = zeros(1,76)'; %流量初始化为0
            %plot(obj.G, 'EdgeLabel', obj.G.Edges.capacity)
            %disp(edgefft)
            
        end
        function PopCon = CalCon(obj,PopDec)
            PopCon = zeros(size(PopDec,1),1);
            for k = 1:size(PopDec,1) %遍历每个种群
                tempG = obj.G; %定义一个临时的图
                for i = 1:3606  %定义3606辆同路车
                    for j = 1:76    %计算每辆车的路径
                        if PopDec(k,i*j) == 1 %如果被选择了，则道路流量+1
                            tempG.Edges.flow(j) = tempG.Edges.flow(j) + 1;
                        end
                    end
                end
                for i = 1:76
                    if tempG.Edges.flow(i) > tempG.Edges.capacity(i)
                        PopCon(k,:) = 1;
                    end
                end
                
                %计算道路合理性
                count = 0;
                for i = 1:24
                    for j = 1:24
                        times = obj.od(i,j);
                        for w = 1:times
                            count = count + 1;
                            perroute = PopDec(k,(((count)-1)*76+1):count*76);
                            if ~routecheck(perroute,obj.fft, i, j)
                                PopCon(k,:) = 1;
                            end
                        end
                    end
                end
                disp(count)

            end       
        end
        function PopObj = CalObj(obj, PopDec)
            PopObj = zeros(size(PopDec,1),2);
            for k = 1:size(PopDec,1) %遍历每个种群
                tempG = obj.G; %定义一个临时的图
                minOS = 0; %系统最优和用户均衡目标值
                minEU = 0;
                %将种群计算出来的解累加到网络里
                for i = 1:3606  %定义3606辆同路车
                    for j = 1:76    %计算每辆车的路径
                        if PopDec(k,i*j) == 1 %如果被选择了，则道路流量+1
                            tempG.Edges.flow(j) = tempG.Edges.flow(j) + 1;
                        end
                    end
                end
                %计算系统最优
                for i = 1:76
                    x_a = tempG.Edges.flow(i); %当前道路流量
                    C_a = tempG.Edges.capacity(i); %当前道路的容量
                    % 计算系统最优
                    minOS = minOS + tempG.Edges.fft(i)*x_a*(1+obj.alpha*((x_a/C_a)^obj.beta));
                    % 计算个人最优
                    minEU = minEU + tempG.Edges.fft(i)*(x_a + ((obj.alpha * C_a)/(obj.beta + 1))*((x_a/C_a)^(obj.alpha+1)));
                end
                PopObj(k,1) = minOS;
                PopObj(k,2) = minEU;
            end
            
        end
              
        
    end
end