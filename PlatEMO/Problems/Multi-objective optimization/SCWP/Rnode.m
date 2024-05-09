classdef Rnode < handle
    properties(Access = public)
        inputNodes
        sellPrice
        inventory
        totalMoney
        sell_1
    end
    
    methods
        function obj = Rnode(inputNodes, sellPrice)
            obj.inputNodes = inputNodes;
            obj.sellPrice = sellPrice;
            obj.inventory = 0;
            obj.totalMoney = 0;
            obj.sell_1 = 0;
        end
        
        function obj = sell(obj)
            obj.sell_1 = obj.inventory * obj.sellPrice;
            obj.totalMoney = obj.totalMoney + obj.sell_1;
            obj.inventory = 0;

        end
    end
end