function test()
    SCenv = SCEnv();
    cellnum = SCenv.normal_status([120,200,120,200,120,200],1,10);
    disp(cellnum)
    for j = 1:numel(SCenv.M1List)
       disp(values(SCenv.M1List{j}.inventory))
       disp(values(SCenv.M1List{j}.totalPurchase))
    end
    disp(SCenv.R.totalMoney)
end
% 计算好像没有问题了，接下来详细写一下，计算部分