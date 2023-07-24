## 大梯子


systemd文件位置
centos:/usr/lib/systemd/system

ubuntu:/etc/systemd/system，但实际部分是从/lib/systemd/system中软连接的

①/etc/systemd/system  存放系统启动的默认级别及启动的unit的软连接，优先级最高。

②/run/systemd/system，系统执行过程中产生的服务脚本，优先级次之。

③/usr/lib/systemd/system 存放系统上所有的启动文件。优先级最低

创建文件 gs_socks.service
centos: echo wocao > /usr/lib/systemd/system/gs_socks.service

ubuntu: echo wocao > /etc/systemd/system/gs_socks_server.service

服务器端
```shell
[Unit]
Description=gs_socks_server
After=network.target

[Service]
Type=simple
# 进程退出立即重启
Restart=always

ExecStart=/root/socks/gs-v3-linux-amd64 start -s
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
```

ubuntu: echo wocao > /etc/systemd/system/gs_socks_client.service

客户端
```shell
[Unit]
Description=gs_socks_client
After=network.target

[Service]
Type=simple
# 进程退出立即重启
Restart=always

ExecStart=/root/socks/gs-v3-linux-amd64 start -c
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
```

启动停止与状态查看
```shell
systemctl stop gs_socks_server
systemctl start gs_socks_server
systemctl status gs_socks_server
```

```shell
systemctl stop gs_socks_client
systemctl start gs_socks_client
systemctl status gs_socks_client
```

如何查看守护进程的实时输出呢
```shell
journalctl -f -u gs_socks_client -o cat
journalctl -f -u gs_socks_server -o cat
```