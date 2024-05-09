classdef PCIP_3 < PROBLEM
    % <single> <integer> <large>
        properties
            conflictMarix 
            disturbMarix 
            confoundMarix	% Optimal decision vector
            ereaID
            Fre
            small_2_pci
            small_2_conflig
            small_2_disturb
            mod3_2_pci
            small_3_pci
            small_3_confound
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

                obj.small_2_pci = load("PCI_cc_2.mat").small_cc_pci;
                obj.small_2_conflig = load("PCI_cc_2.mat").small_cc_conflig;
                obj.small_2_disturb = load("PCI_cc_2.mat").small_cc_disturb;
                obj.mod3_2_pci = mod(obj.small_2_pci,3);
                %混淆矩阵
                obj.small_3_pci = load("PCI_d_3.mat").small_d_pci;
                obj.small_3_confound = load("PCI_d_3.mat").small_d_confound;
                disp("init finish!")
            end
            %% Calculate objective values
            function PopObj = CalObj(obj,PopDec)
                mod3Dec = mod(PopDec,3);
                disp("new turn")
                for k = 1:size(PopDec,1) %遍历每个种群
                    %开始计算冲突
                    myDec = PopDec(k,:);
                    premod3Dec = mod3Dec(k,:);
                    sumconflig = 0;
                    sumdisturb = 0;
                    sumconfound = 0;
                    for i = 1:2067 %查找有没有重复的
                        for j = i:2067
                            if myDec(i) == myDec(j) && obj.Fre(i) == obj.Fre(j)
                                sumconfound = sumconfound + obj.confoundMarix(i, j) + obj.confoundMarix(j, i);
                                sumconflig = sumconflig + obj.conflictMarix(i,j) + obj.conflictMarix(j,i); 
                            end
                            if obj.Fre(i) == obj.Fre(j)
                                if premod3Dec(i) == premod3Dec(j)
                                    sumdisturb = sumdisturb + obj.disturbMarix(i,j) + obj.disturbMarix(j,i);
                                end
                            end
                        end
                    end
                    for i = 1:2067 %小矩阵开始计算，其他小区和2067交互情况
                        for j = 1:1246
                            if myDec(i) == obj.small_2_pci(j)
                                sumconflig = sumconflig + obj.small_2_conflig(i,j);
                            end
                            if premod3Dec(i) == obj.mod3_2_pci(j)
                                sumdisturb = sumdisturb + obj.small_2_disturb(i,j)*2;
                            end
                        end
                    end
                    for i = 1:2067
                        for j = 1:1192
                            if myDec(i) == obj.small_3_pci(j)
                                sumconfound = sumconfound + obj.small_3_confound(i,j);
                            end
                        end
                    end
                    PopObj(k,1) = sumconflig + sumdisturb + sumconfound;
                end
            end  
        end
end