classdef SCWP < PROBLEM
% <multi> <real> <constrained>
% Pressure vessal problem

%------------------------------- Reference --------------------------------
% A. Kumar, G. Wu, M. Ali, Q. Luo, R. Mallipeddi, P. Suganthan, and S. Das,
% A benchmark-suite of real-world constrained multi-objective optimization
% problems and some baseline results, Swarm and Evolutionary Computation,
% 2021, 67: 100961.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2023 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
    %--------------------------------------------------------------------------
    methods
        function Setting(obj)
            %算法部分
            obj.M = 2;
            obj.D = 72;
            obj.lower = zeros(1, 72);  %上限和下限还没编写
            pattern = [500, 1000];
            myup = repmat(pattern, 1, 36);
            obj.upper = myup;
            obj.encoding = 2 * ones(1, 72);   %决策变量
            %obj.st = 0;     %系统运行的时间，一共是15天
            %obj.lastst = 0; %存储上一次的时间           
        end
        function PopCon = CalCon(obj,PopDec)
            PopCon = zeros(size(PopDec,1),1);
            for i = 1:size(PopDec, 1)
                SCenv = SCEnv();
                cellnum = SCenv.normal_status(PopDec(i,:),1,12);
                
                if cellnum(1) > 0
                    PopCon(i,:) = 1;
                end   
            end   
            
        end
        function PopObj = CalObj(~, x)
            PopObj = [];
            for i = 1:size(x, 1)
                SCenv = SCEnv();
                cellnum = SCenv.normal_status(x(i,:),1,12);
                PopObj = [PopObj; cellnum];
            end          
        end
    end
end