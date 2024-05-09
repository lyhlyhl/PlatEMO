% SC Node
classdef SCnode < handle
    properties
        name
        stype
        disruptions
        price
    end
    
    methods
        function obj = SCnode(stype, name, price)
            obj.name = name;
            obj.stype = stype;
            obj.disruptions = false;
            obj.price = price;
        end
        
        function obj = disrupt(obj)
            obj.disruptions = true;
        end
    end
end