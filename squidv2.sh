#!/bin/bash

# 脚本版本号
script_version="1.13"
# 配置多IP
update_ipacl() {
    echo "正在获取本机所有IP"
    ip_addresses=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo "正在写入多IP规则"
    index=1
    for ip in $ip_addresses; do
        acl_name="ip_$index"
        echo -n "acl $acl_name myip $ip" >> /etc/squid/squid.conf
        echo " tcp_outgoing_address $ip $acl_name" >> /etc/squid/squid.conf
        index=$((index+1))
    done
}

# 更新脚本
update_script() {
    echo "正在更新脚本..."
    rm -f /root/squid.sh
    wget -O /root/squid.sh https://raw.githubusercontent.com/pico8scp/http/main/squid.sh
    chmod +x /root/squid.sh
    echo "脚本已更新，正在重新启动脚本！"
    ./squid.sh
    exit 0
}

# 安装Squid
install_squid() {
    yum install -y squid
    yum install httpd-tools
    echo "Squid已安装！"
}

# 备份Squid配置文件
backup_config() {
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
    echo "Squid配置文件已备份！"
}

# 复写Squid配置文件
rewrite_config() {
    rm /etc/squid/squid.conf
    touch /etc/squid/squid.conf
    cat > /etc/squid/squid.conf << EOF
#一、网段配置
acl localnet src 10.0.0.0/8	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
acl localnet src 192.168.0.0/16	# RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
#填入可使用squid的网段
acl local    src 192.168.10.0/24
acl local    src 192.168.20.0/24
acl local    src 192.168.30.0/24



#二、端口配置
acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http



#三、密码策略
# test mypass 设置squid的密码策略
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 15
auth_param basic credentialsttl 2 hours
auth_param basic casesensitive on         #用户名不区分大小写，可改为ON区分大小写
auth_param basic realm proxy



#四、acl规则配置。先配置一个变量，在配置该变量的限制

#<1>编写变量
#mp4相关限制的变量
#acl MYLAN src 192.168.2.0/24              #源地址网段    
#acl MC20 maxconn 20                       #最大并发连接
#acl DOMAIN dstdomain .qq.com .msn.com     #目标为.qq.com .msn.com的域名
#acl FILE urlpath_regex -i \.mp3$ \.mp4$   #以.mp3 .mp4结尾的URL路径
#acl TIME time MTWHF 07:30-17:30           #时间为周一至周五早8:30至晚17:30
#acl vip arp 00：7c:23:76:5C:1C	           #设置某个mac地址变量为vip



#设置黑名单 填入文件中的网址不可访问，一行一个网址
acl CONNECT method CONNECT
acl blocked_sites dstdomain "/etc/squid/blocked_sites"
acl authenticated proxy_auth REQUIRED


#<2>设置acl访问控制规则.
#有先后顺序,第一条规则匹配上就不再继续往下，所以先把拒绝写在前面
#mp4相关变量的限制
#http_access deny MYLAN FILE         #禁止客户机下载MP3 MP4文件
#http_access deny MYLAN DOMAIN       #禁止客户机访问acl列表中的网站
#http_access deny MYLAN MC20         #客户机的并发连接超过20时将被阻止
#http_access allow MYLAN TIME        #允许客户机在工作时间访问互联网

http_access deny blocked_sites       #限制变量blocked_sites的访问
#http_access deny !Safe_ports
#http_access deny CONNECT !SSL_ports
http_access allow authenticated
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
#http_access allow vip                #允许变量vip访问
#http_access deny all


http_port 10801                       #配置squid端口号
coredump_dir /var/spool/squid
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320



#五、配置不同模式

#高密配置，隐藏真实ip变成匿名代理 这是squid3.1
via off
forwarded_for delete
request_header_access X-Forwarded-For deny all  
request_header_access From deny all  
request_header_access Via deny all 


#透明配置（最方便使用，最不安全）
#http_port 3128 transparent
#cache_mem 99 MB
#cache_swap_low 90
#cache_swap_high 95
#maximum_object_size 4M
#minimum_object_size 0 KB
#maximum_object_size_in_memory 4096 KB
#memory_replacement_policy lru
#maximum_object_size 4 MB                    #允许保存到缓存空间的最大对象大小，以KB为单位，超过大小限制的文件将不被缓存，而是直接转发给用户
#cache_dir ufs /var/spool/squid 100 16 256 
#access_log /var/log/squid/access.log

#使用透明配置时，下方2个要填入对应位置
#acl all src 0.0.0.0/0.0.0.0                 #配置变量。允许所有ip访问， all是一个名字，可以随便起
#http_access allow all                       #配置该变量的acl限制。允许上面定义的all这个规则访问
EOF
    echo "Squid配置文件已复写！"
}

# 创建用户名密码
create_user() {
    if [ -f /etc/squid/passwd ]; then
        rm /etc/squid/passwd
        echo "旧的用户名密码文件已删除！"
    fi

    echo "请输入用户名："
    read -r username
    echo "请输入密码："
    read -rs password
    htpasswd -b -c /etc/squid/passwd "$username" "$password"
    echo "用户名和密码已创建！"
}

# 重启Squid服务
restart_service() {
    systemctl restart squid
    echo "Squid服务已重启！"
}

# 卸载Squid
uninstall_squid() {
    yum remove -y squid
    echo "Squid已卸载！"
}

# 交互菜单
while true; do
    echo "-------------------------"
    echo "HTTP代理一键脚本（版本：1.12）"
    echo "请选择要执行的操作："
    echo "1. 安装Squid"
    echo "2. 备份Squid配置文件"
    echo "3. 复写Squid配置文件"
    echo "4. 创建用户名密码"
    echo "5. 重启Squid服务"
    echo "6. 卸载Squid"
    echo "7. 退出"
    echo "8. 更新脚本"
    echo "9. 多IP匹配"
    echo "-------------------------"

    read -r choice

    case $choice in
        1) install_squid ;;
        2) backup_config ;;
        3) rewrite_config ;;
        4) create_user ;;
        5) restart_service ;;
        6) uninstall_squid ;;
        7) break ;;
        8) update_script ;;
        9) update_ipacl ;;
        *) echo "无效的选项，请重新选择！" ;;
    esac

    echo
done
