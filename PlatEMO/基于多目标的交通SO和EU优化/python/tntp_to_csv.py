import csv
with open("./data/SiouxFalls/SiouxFalls_net.tntp", 'r', newline='') as f:
    lines = f.readlines()
    # print(lines)
    netdata = []
    for e, line in enumerate(lines):
        line = line.split("	")
        line = line[1:-1]
        print(line)
        dadic = {}
        dadic["id"] = str(e)
        dadic["from"] = line[0]
        dadic["to"] = line[1]
        dadic["capacity"] = line[2]
        dadic["free_flow_time"] = line[4]
        netdata.append(dadic)

with open("./data/SiouxFalls/SiouxFalls_net_my.csv", 'w', newline='') as csvfile:
    # 定义 CSV 文件的字段名
    fieldnames = ['id', 'from', 'to', 'capacity', 'free_flow_time']

    # 创建一个 CSV writer 对象
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    # 写入字段名
    writer.writeheader()

    # 写入数据
    for d in netdata:
        writer.writerow(d)

print("CSV 文件写入完成！")