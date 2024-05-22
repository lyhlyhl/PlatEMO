import pandas as pd
import networkx as nx

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

def main():
    G = build_network("./data/SiouxFalls/SiouxFalls_net_my.csv", "./data/SiouxFalls/SiouxFalls_node.csv")


if __name__ == '__main__':
    main()