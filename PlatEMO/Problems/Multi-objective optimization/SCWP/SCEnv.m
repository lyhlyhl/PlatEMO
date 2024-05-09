classdef SCEnv
    %SCENV 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        SC1
        SC2
        SC3
        M11
        M12
        M13
        M2
        R
        M1List
        st
        pricemap
    end
    
    methods
        function obj = SCEnv()
            %SCENV 构造此类的实例
            %   此处显示详细说明
            obj.SC1 = SCnode("tin", "sc1", 200);
            obj.SC2 = SCnode("iron", "sc2", 50);
            obj.SC3 = SCnode("resin", "sc3", 10);
            obj.M11 = M1node({obj.SC1, obj.SC2}, "m11", "Res", 500);
            obj.M12 = M1node({obj.SC1, obj.SC2}, "m12", "Cap", 500);
            obj.M13 = M1node({obj.SC3}, "m13", "PCB", 1000);
            obj.M2 = M2node({obj.M11, obj.M12, obj.M13}, "M2", 500);
            obj.R = Rnode({obj.M2}, 1000);
            obj.M1List = {obj.M11, obj.M12, obj.M13};
            % 定义几个结点的后继节点
            obj.M11.defOutNode(obj.M2);
            obj.M12.defOutNode(obj.M2);
            obj.M13.defOutNode(obj.M2);
            obj.M2.defOutNode(obj.R);
            obj.st = 0;

            obj.pricemap = containers.Map({'tin', 'iron', 'resin','Res','Cap','PCB'}, {200, 50, 10,250,250,10});
            %obj.Acost = 0;
        end
        function obj = step(obj, x)
            %if 
            x_dec = x; %决策变量，目前还用不到
            for a = 0:2 %调整决策变量
                obj.M1List{a+1}.Adjust(x_dec(a*2+1), x_dec(a*2+2));
            end
            for j = 1:numel(obj.M1List)
                obj.M1List{j}.produce(); 
                obj.M1List{j}.costCalculate(1); %num为存储费用倍率，
            end
            obj.M2.produce();

            obj.R.sell();
            %obj.st = obj.st + 1;
            
        end

        function cellnum = normal_status(obj, x, t1, t2)
            allpurchase = 0;
            allsitefee = 0;
            allinven = 0;
            allsell = 0;
            totalinven = 0;
            for i = t1:t2
                if i == 4
                    obj.SC1.disruptions = true;
                end
                if i == 9
                    obj.SC1.disruptions = false;
                end
                obj.step(x(6*(i-1)+1:i*6)); %运行的个时间片
                for j = 1:numel(obj.M1List)
                    allpurchase = allpurchase + obj.M1List{j}.purchasefee_1; %计算购买成本和存储成本
                    allsitefee = allsitefee + obj.M1List{j}.sitefee_1;
                end 
                allsell = allsell + obj.R.sell_1; 
                for a = 1:numel(obj.M1List) %计算多余库存
                    keys = obj.M1List{a}.inventory.keys;
                    for b = 1:numel(keys)
                        key = keys{b};
                        totalinven =  totalinven + obj.M1List{a}.inventory(key); 
                    end
                end
                %disp(totalinven)
            end
            for j = 1:numel(obj.M1List) %计算多余库存，多余库存按70%计算
                keys = obj.M1List{j}.inventory.keys;
                for i = 1:numel(keys)
                    key = keys{i};
                    allinven = allinven + 0.7 * (obj.pricemap(key) * obj.M1List{j}.inventory(key)); 
                end
            end
            %这里计算还是有问题，没有计算M2的存储成本和仓促折扣
            %计算利润，几项分别为销售额 购买成本 存储成本 仓储折扣价值
            allprofit = allsell - allpurchase - allsitefee + allinven;

            %这里计算韧性，用最大产能-真实产能 来衡量韧性
            relise = obj.M11.speed - obj.M11.minProNum + obj.M12.speed - obj.M12.minProNum + obj.M13.speed - obj.M13.minProNum;

            totalinven = totalinven / (t2 - t1 + 1);
            %relise = totalinven / 5;
            %cellnum = [allsell, allpurchase, allsitefee, allinven, allprofit, relise];
            cellnum = [-allprofit, relise];
        end
        % function x = cal(obj)

        % end

        % function obj = run(obj)
        % end

        % function money = calmoney_1(obj)
            
        % end
    end
end

% function supplychain()
%     % 定义结点部分
%     SC1 = SCnode("tin", "sc1", 200);
%     SC2 = SCnode("iron", "sc2", 50);
%     SC3 = SCnode("resin", "sc3", 10);
%     M11 = M1node({SC1, SC2}, "m11", "Res", 1000);
%     M12 = M1node({SC1, SC2}, "m12", "Cap", 1000);
%     M13 = M1node({SC3}, "m13", "PCB", 1000);
%     M2 = M2node({M11, M12, M13}, "M2", 1000);
%     R = Rnode({M2}, 3000);
%     M1List = {M11, M12, M13};
%     % 定义几个结点的后继节点
%     M11.defOutNode(M2);
%     M12.defOutNode(M2);
%     M13.defOutNode(M2);
%     M2.defOutNode(R);
%     % 开始制造
%     for i = 1:15
%         if i == 4
%             SC2.disruptions = true;
%         end
%         if i == 10
%             SC2.disruptions = false;
%         end
%         for j = 1:numel(M1List)
%             M1List{j}.produce();
%             M1List{j}.costCalculate();
%         end
%         M2.produce();
%         R.sell();
%     end
%     %计算一些值
%     totalCost = 0;  %总的惩罚花费
%     totalPurchasefee = 0; %购买部分的花费
%     %总的花费就是上面俩个相加的结果
%     for j = 1:numel(M1List)
%         totalCost = totalCost + M1List{j}.sitefee + M1List{j}.goodsfee;
%         totalPurchasefee = totalPurchasefee + M1List{j}.purchasefee;
%     end
%     disp(R.totalMoney);
%     %for j = 1:numel(M1List)
%     %    disp(values(M1List{j}.inventory))
%     %    disp(values(M1List{j}.totalPurchase))
%     %end
%     %disp(values(M2.inventory))
%     disp(R.totalMoney - totalPurchasefee);
%     disp(R.totalMoney - totalPurchasefee - totalCost);
%     %到这里都是计算花费
% end