%M2 node 
classdef M2node < handle
    properties(SetAccess = public)
        inputNode
        name
        speed
        outputNode
        inventoryMax
        inventory
        inventorySafeRate
        produceNum
        minProNum
    end
    
    methods
        %some definitions are same to M1node
        function obj = M2node(inputNode, name, speed)
            obj.inputNode = inputNode;
            obj.name = name;
            obj.speed = speed;
            obj.outputNode = [];
            obj.inventoryMax = 1000;
            obj.inventory = containers.Map('KeyType', 'char', 'ValueType', 'double');
            keys = {'Res', 'Cap', 'PCB'};
            for i = 1:numel(keys)
                key = keys{i};
                obj.inventory(key) = 0;
            end
            obj.minProNum = 1000;
            obj.inventorySafeRate = 0.2;
            obj.produceNum = 150;
        end
        
        function obj = defOutNode(obj, output)
            obj.outputNode = output;
        end
        
        function obj = produce(obj)
            produceFlag = true;

            proNum = min(cell2mat(values(obj.inventory))); %生产能生产的最小值
            proNum = min(proNum, obj.speed); %不能超过每日最大速度
            obj.minProNum = min(proNum, obj.minProNum);
            obj.outputNode.inventory = obj.outputNode.inventory + proNum;  %
            keys = obj.inventory.keys;
            for i = 1:numel(keys)
                obj.inventory(keys{i}) = obj.inventory(keys{i}) - proNum;
            end
        end
        
        function obj = Adjust(obj, produceNum, Rate)
            obj.produceNum = produceNum;
            obj.inventorySafeRate = Rate;
        end
    end
end