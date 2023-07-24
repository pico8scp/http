#!/bin/bash

# 安装所需的运行环境
sudo apt update
sudo apt install -y git make

# 克隆Git库
git clone https://github.com/pico8scp/http.git

# 进入克隆下来的目录
cd http

# 编译软件
make

# 将可执行文件移动到指定目录
mkdir -p /root/socks
mv gs-v3-linux-amd64 /root/socks/

# 配置服务端守护程序
cat > /etc/systemd/system/gs_socks_server.service << EOL
[Unit]
Description=gs_socks_server
After=network.target

[Service]
Type=simple
Restart=always

ExecStart=/root/socks/gs-v3-linux-amd64 start -s
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
EOL

# 配置客户端守护程序
cat > /etc/systemd/system/gs_socks_client.service << EOL
[Unit]
Description=gs_socks_client
After=network.target

[Service]
Type=simple
Restart=always

ExecStart=/root/socks/gs-v3-linux-amd64 start -c
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
EOL

# 创建启动脚本
cat > /root/start_socks.sh << EOL
#!/bin/bash

systemctl start gs_socks_server
systemctl start gs_socks_client
EOL

# 赋予启动脚本执行权限
chmod +x /root/start_socks.sh

# 启用服务
systemctl enable gs_socks_server
systemctl enable gs_socks_client

# 启动守护程序
bash /root/start_socks.sh
