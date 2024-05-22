import pandas as pd
import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
from scipy.optimize import minimize_scalar

# 读取CSV文件 构建网络
def build_network(Link_path, Node_path):
    # 读取点数据、边数据
    links_df = pd.read_csv(Link_path)
    # 需要注意使用from_pandas_edge，其读取的边的顺序和csv中边的顺序有差异
    G = nx.from_pandas_edgelist(links_df, source='from', target='to', edge_attr=['capacity','fft'],
                                create_using=nx.DiGraph())
    nx.set_edge_attributes(G, 0, 'flow_temp')
    nx.set_edge_attributes(G, 0, 'flow_real')
    nx.set_edge_attributes(G, 0, 'descent')
    nx.set_edge_attributes(G, nx.get_edge_attributes(G, "fft"), 'weight')

    # 获取节点位置信息
    nodes_df = pd.read_csv(Node_path)
    node_positions = {}
    for index, row in nodes_df.iterrows():
        node_positions[row['Node']] = (row['X'], row['Y'])
    # 更新图中节点的位置属性
    nx.set_node_attributes(G, node_positions, 'pos')
    return G

# 绘制网络
def draw_network(G):
    pos = nx.get_node_attributes(G, "pos")
    nx.draw(G, pos, with_labels=True, node_size=200, node_color='lightblue', font_size=10, font_weight='bold')
    plt.show()

# 计算BPR路阻
def BPR(fft, flow, capacity, alpha=0.15, beta=4.0):
    return fft * (1 + alpha * (flow / capacity) ** beta)


def all_none_initialize(G, od_df):
    # 这个函数仅使用一次，用于初始化
    # 在零流图上，按最短路全有全无分配，用于更新flow_real
    for _, _, data in G.edges(data=True):
        data['capacity'] = round(data['capacity'] / 100)
        print(data['capacity'])
    for _, od_data in od_df.iterrows():
        od_data["demand"] = od_data["demand"] / 100
    for _, od_data in od_df.iterrows():
        source = od_data["o"]
        target = od_data["d"]
        demand = od_data["demand"]
        # 计算最短路径
        shortest_path = nx.shortest_path(G, source=source, target=target, weight="weight")
        # 更新路径上的流量
        for i in range(len(shortest_path) - 1):
            u = shortest_path[i]
            v = shortest_path[i + 1]
            G[u][v]['flow_real'] += demand
    # 初始化流量后，更新阻抗
    for _, _, data in G.edges(data=True):
        data['weight'] = BPR(data['fft'], data['flow_real'], data['capacity'])


def all_none_temp(G, od_df):
    # 这个是虚拟分配，用于得到flow_temp
    # 每次按最短路分配前，需要先将flow_temp归零
    nx.set_edge_attributes(G, 0, 'flow_temp')
    for _, od_data in od_df.iterrows():
        # 每次更新都得读OD，后面尝试优化这个
        source = od_data["o"]
        target = od_data["d"]
        demand = od_data["demand"]
        # 计算最短路径
        shortest_path = nx.shortest_path(G, source=source, target=target, weight="weight")
        # 更新路径上的流量
        for i in range(len(shortest_path) - 1):
            u = shortest_path[i]
            v = shortest_path[i + 1]
            # 更新流量
            G[u][v]['flow_temp'] += demand


def get_descent(G):
    for _, _, data in G.edges(data=True):
        data['descent'] = data['flow_temp'] - data['flow_real']


def objective_function(temp_step, G ):
    s, alpha, beta = 0, 0.15, 4.0
    for _, _, data in G.edges(data=True):
        x = data['flow_real'] + temp_step * data['descent']
        s += data["fft"] * (x + alpha * data["capacity"] / (beta + 1) * (x / data["capacity"]) ** (beta + 1))
    return s


# def objective_function(temp_step, G):
#     s, alpha, beta = 0, 0.15, 4.0
#     for _, _, data in G.edges(data=True):
#         x = data['flow_real'] + temp_step * data['descent']
#         s += x * BPR(data["fft"], x, data["capacity"])
#     return s
def update_flow_real(G):
    # 这个函数用于调整流量，即flow_real，并更新weight
    best_step = get_best_step(G)  # 获取最优步长
    for _, _, data in G.edges(data=True):
        # 调整流量，更新路阻
        data['flow_real'] += best_step * data["descent"]
        data['weight'] = BPR(data['fft'], data['flow_real'], data['capacity'])


def get_best_step(G, tolerance=1e-4):
    result = minimize_scalar(objective_function, args=(G,), bounds=(0, 1), method='bounded', tol=tolerance)
    return result.x


def main():
    G = build_network("../data/SiouxFalls/SiouxFalls_net_my.csv", "../data/SiouxFalls/SiouxFalls_node.csv")  # 构建路网
    #draw_network(G)  # 绘制交通路网图
    od_df = pd.read_csv("../data/SiouxFalls/SiouxFalls_od.csv")  # 获取OD需求情况
    all_none_initialize(G, od_df)  # 初始化路网流量
    print("初始化流量", list(nx.get_edge_attributes(G, 'flow_real').values()))

    epoch = 0  # 记录迭代次数
    err, max_err = 1, 1e-4  # 分别代表初始值、最大容许误差
    f_list_old = np.array(list(nx.get_edge_attributes(G, 'flow_real').values()))
    while err > max_err:
        epoch += 1
        all_none_temp(G, od_df)  # 全有全无分配，得到flow_temp
        get_descent(G)  # 计算梯度，即flow_temp-flow_real
        update_flow_real(G)  # 先是一维搜索获取最优步长，再调整流量，更新路阻

        # 计算并更新误差err
        f_list_new = np.array(list(nx.get_edge_attributes(G, 'flow_real').values()))  # 这个变量是新的路网流量列表
        d = np.sum((f_list_new - f_list_old) ** 2)
        err = np.sqrt(d) / np.sum(f_list_old)
        f_list_old = f_list_new

    s, alpha, beta = 0, 0.15, 4.0

    for _, _, data in G.edges(data=True):
        x = data['flow_real']
        s += data["fft"] * (x + alpha * data["capacity"] / (beta + 1) * (x / data["capacity"]) ** (beta + 1))
    print("均衡流量", list(nx.get_edge_attributes(G, 'flow_real').values()))
    print("迭代次数", epoch)
    print("最小值", s)
    for _, _, data in G.edges(data=True):
        x = data['flow_real']
        s += x * BPR(data["fft"], x, data["capacity"])
    print("迭代次数", epoch)
    print("最小值2", s)
    # 导出网络均衡流量
    df = nx.to_pandas_edgelist(G)
    df = df[["source", "target", "flow_real"]].sort_values(by=["source", "target"])
    df.to_csv("网络均衡结果.csv", index=False)


if __name__ == '__main__':
    main()
# G = build_network("./data/SiouxFalls/SiouxFalls_net_my.csv", "./data/SiouxFalls/SiouxFalls_node.csv")
# draw_network(G)