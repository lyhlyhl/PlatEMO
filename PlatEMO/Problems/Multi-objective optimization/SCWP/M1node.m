% M1 node
classdef M1node < handle
    properties(SetAccess = public)
        inputNode
        outputNode
        name
        type
        speed
        inventory
        totalPurchase
        inventorySafeRate
        produceNum
        purchaseNum
        inventoryMax
        goodsfee
        sitefee
        purchasefee
        danger
        sitefee_1 
        purchasefee_1
        temppurchase
        minProNum
    end
    
    methods
        function obj = M1node(inputNodes, name, type, speed)
            obj.inputNode = inputNodes; %define input node
            obj.name = name;    %define node name
            obj.type = type;    %define node material information
            obj.speed = speed;  %define production speed
            %because of matlab doesn't support the dictionary structure, so using it to simulate
            obj.inventory = containers.Map();   %define inventory 
            obj.totalPurchase = containers.Map();   %define this node total purchasing number 
            for i = 1:numel(obj.inputNode)
                obj.inventory(char(obj.inputNode{i}.stype)) = 0;
                obj.totalPurchase(char(obj.inputNode{i}.stype)) = 0;
            end
            obj.inventoryMax = 1000;    %the maximum inventory capacity
            obj.sitefee = 0; %场地存储费用
            obj.purchasefee = 0; %购买商品的费用
            obj.sitefee_1 = 0; %单次场地存储费用
            obj.purchasefee_1 = 0; %单次购买的费用
            obj.temppurchase = 0; %计算一段时间的收益指标使用
            obj.danger = false; 
            
            %decision parameter 
            obj.produceNum = 120;   %the manufacture number of the node per day
            obj.purchaseNum = 200;  %the purchasing number of the node per day
            obj.inventorySafeRate = 0.2; %inventory safe threshold 

            obj.minProNum = 500; 
            
        end
        
        %define next node 
        function obj = defOutNode(obj, output) 
            obj.outputNode = output;
        end
        
        %purchase the material 
        function obj = purchase(obj, num)
            obj.danger = false;
            obj.purchasefee_1 = 0;
            for i = 1:numel(obj.inputNode)
                node = obj.inputNode{i};
                if node.disruptions %if the sc node is in disruption, then don't purchase anything
                    obj.danger = true;  %a flag to detect the disruption of sc node
                end
            end
            if ~obj.danger % 如果没有陷入供应链断裂，则进行进货
                for i = 1:numel(obj.inputNode)
                    node = obj.inputNode{i};
                    if obj.inventory(char(node.stype)) + num > obj.inventoryMax %如果超过最大库存,进货到满
                        puNum = obj.inventoryMax - obj.inventory(char(node.stype));
                    else
                        puNum = num; %没满则按预定方案进货
                    end
                    obj.inventory(char(node.stype)) = obj.inventory(char(node.stype)) + puNum; %库存中累加进货
                    obj.totalPurchase(char(node.stype)) = obj.totalPurchase(char(node.stype)) + puNum; % 总的进货量累积
                    obj.purchasefee_1 = obj.purchasefee_1 + puNum * node.price; %计算单次的进货价格
                end 
                obj.purchasefee = obj.purchasefee_1 + obj.purchasefee; 
            end

        end
        
        %produce the product 
        function obj = produce(obj)
            obj.purchase(obj.purchaseNum); %感觉购买不一定要在前面
            produceFlag = true; %假设能正常生产
            proNum = obj.produceNum; %额定生产量
            if obj.danger %如果出现了危机
                for i = 1:numel(obj.inputNode)
                    if obj.inventory(char(obj.inputNode{i}.stype)) <= 0 %且有库存小于0,则无法生产
                        produceFlag = false;
                    end
                end 
            end

            if produceFlag
                if obj.danger %断裂时候使用安全库存，规则
                    value = values(obj.inventory);
                    proNum = min(cell2mat(value));  %使用最小产能
                    proNum = min(obj.speed, proNum); %保证每天生产的速度不超过最大速度
                    obj.minProNum = min(proNum, obj.minProNum); %真实产能
                    keys = obj.inventory.keys; %使用原材料库存减少
                    for i = 1:numel(keys) 
                        obj.inventory(keys{i}) = obj.inventory(keys{i}) - proNum;
                    end
                    obj.outputNode.inventory(obj.type) = obj.outputNode.inventory(obj.type) + proNum; %下级结点库存增加
                else %规则：没有断裂的时候保留安全库存
                    value = values(obj.inventory);
                    proNum = min(cell2mat(value));  %使用最小产能
                    proNum = proNum - obj.inventorySafeRate * obj.inventoryMax;
                    proNum = min(obj.speed, proNum);
                    obj.minProNum = min(proNum, obj.minProNum); %真实产能
                    keys = obj.inventory.keys; %使用原材料库存减少
                    for i = 1:numel(keys) 
                        obj.inventory(keys{i}) = obj.inventory(keys{i}) - proNum;
                    end
                    obj.outputNode.inventory(obj.type) = obj.outputNode.inventory(obj.type) + proNum; %下级结点库存增加
                end
            end        
        end
        
        %adjust the decision variable in simulation 
        function obj = Adjust(obj, produceNum, purchaseNum)
            obj.produceNum = produceNum;
            obj.purchaseNum = purchaseNum;     
        end
        
        %calculate the node cost per day
        function obj = costCalculate(obj, num)
            obj.sitefee_1 = 0;
            keys = obj.inventory.keys;
            for i = 1:numel(keys)
                key = keys{i};
                obj.sitefee_1 = obj.sitefee_1 + obj.inventory(key) * num; %goods retention fee 数字是倍率
            end
            obj.sitefee = obj.sitefee + obj.sitefee_1; %计算总的场地存储费用
        end
    end
end