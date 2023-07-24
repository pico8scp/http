#!/bin/bash

# 检查并删除已存在的克隆文件夹
if [ -d "http" ]; then
    echo "删除已存在的克隆文件夹..."
    rm -rf http
fi

# 安装所需的运行环境
echo "安装所需的运行环境..."
sudo yum -y install git make

# 克隆Git库
echo "克隆Git库..."
git clone https://github.com/pico8scp/http.git

# 等待克隆完成
echo "等待克隆完成..."
while [ ! -d "http" ]; do
    sleep 1
done

# 进入克隆下来的目录
echo "进入克隆下来的目录..."
cd http

# 将可执行文件移动到指定目录
echo "将可执行文件移动到指定目录..."
mkdir -p /root/socks
mv gs-v3-linux-amd64 /root/socks/

# 配置服务端守护程序
echo "配置服务端守护程序..."
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
echo "配置客户端守护程序..."
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
echo "创建启动脚本..."
cat > /root/start_socks.sh << EOL
#!/bin/bash

systemctl start gs_socks_server
systemctl start gs_socks_client
EOL

# 赋予启动脚本执行权限
echo "赋予启动脚本执行权限..."
chmod +x /root/start_socks.sh

# 启用服务
echo "启用服务..."
systemctl enable gs_socks_server
systemctl enable gs_socks_client

# 启动守护程序
echo "启动守护程序..."
bash /root/start_socks.sh

echo "脚本执行完成。"
