function result = routecheck(myroute,myfft, node1, node2)
    fft = myfft;
    % 创建完整图
    % 创建子图
    subG = digraph;
    route = myroute;
    for i=1:76
        if route(i) == 1
            subG = addedge(subG,fft(i,1),fft(i,2));
        end
    end
    pathnum = sum(route);
    %disp(pathnum)
    % 检查子图是否连通且无环
    % 使用 BFS 从 node1 检查是否能到 node2
    [dist, ~, ~] = shortestpath(subG, node1, node2);
    result = 1;
    if length(dist) == 0
        %disp("第一个");
        result = 0;
    elseif length(dist) - 1 ~= pathnum
        %disp("第二个");
        result = 0;
    end
    return
end