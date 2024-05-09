classdef PCIP_1 < PROBLEM
% <single> <integer> <large>
    properties
        conflictMarix 
        disturbMarix 
        confoundMarix	% Optimal decision vector
        ereaID
        Fre
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            obj.M = 1;
            if isempty(obj.D); obj.D = 2067; end
            obj.lower    = zeros(1,obj.D);
            obj.upper    = ones(1, obj.D) * 1007;
            obj.encoding = ones(1,obj.D) * 2;
            obj.conflictMarix = zeros(2067); %2067*2067的0矩阵
            obj.disturbMarix = zeros(2067);
            obj.confoundMarix = zeros(2067);
            excel_file1 = "2067小区.xlsx";
            data1 = readmatrix(excel_file1); % 读取小区数据
            obj.ereaID = data1(:, 1); %获得2067个小区的ID
            obj.Fre = data1(:, 2);%获得频率
            excel_file2 = "2067小区干扰&冲突.xlsx";
            data2 = readmatrix(excel_file2);
            for row = 1:size(data2,1)
                index1 = find(obj.ereaID ==data2(row,1));
                index2 = find(obj.ereaID ==data2(row,2));
                obj.conflictMarix(index1, index2) = data2(row,3); %存入冲突矩阵
                obj.disturbMarix(index1, index2) = data2(row,4); %存入干扰矩阵
            end
            excel_file3 = "2067小区混淆.xlsx";
            data3 = readmatrix(excel_file3);
            for row = 1:size(data3,1)
                index1 = find(obj.ereaID ==data3(row,1));
                index2 = find(obj.ereaID ==data3(row,2));
                obj.confoundMarix(index1, index2) = data3(row,3); %存入混淆矩阵
                obj.confoundMarix(index2, index1) = data3(row,3);
            end
            b = obj.confoundMarix;
            save('confoundMarix.mat', 'b');
            disp("init finish!")
        end
        %% Calculate objective values
        function PopObj = CalObj(obj,PopDec)
            for k = 1:size(PopDec,1) %遍历每个种群
                %开始计算冲突
                myDec = PopDec(k,:);
                sumconflig = 0;
                sumdisturb = 0;
                sumconfound = 0;
                %模三没同频
                %confoundMarix是个上三角矩阵
                for i = 1:2067 %查找有没有重复的
                    for j = i:2067
                        if myDec(i) == myDec(j)
                            sumconfound = sumconfound + obj.confoundMarix(i, j) + obj.confoundMarix(j, i);
                            if obj.Fre(i) == obj.Fre(j)
                                sumconflig = sumconflig + obj.conflictMarix(i,j) + obj.conflictMarix(j,i); 
                                if mod(myDec(i),3) == mod(myDec(j),3) 
                                    sumdisturb = sumconflig + obj.disturbMarix(i,j) + obj.disturbMarix(j,i);
                                end
                            end
                        end
                    end
                end
                %disp(sumconflig)
                PopObj(k,1) = sumconflig + sumdisturb + sumconfound;
            end
        end
    end
end