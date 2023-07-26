#!/bin/bash

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
    cat > /etc/squid/squid.conf << EOF
#
# Recommended minimum configuration:
#

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 10.0.0.0/8	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
acl localnet src 192.168.0.0/16	# RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

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
acl CONNECT method CONNECT

#
# Recommended minimum Access Permission configuration:
#
# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
#http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access allow fAAynkaCxxUg

# Squid normally listens to port 3128
http_port 80

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

#
# Add any of your own refresh_pattern entries above these.
#
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
acl 112233 proxy_auth REQUIRED
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
auth_param basic casesensitive off
EOF
    echo "Squid配置文件已复写！"
}

# 创建用户名密码
create_user() {
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
    echo "请选择要执行的操作："
    echo "1. 安装Squid"
    echo "2. 备份Squid配置文件"
    echo "3. 复写Squid配置文件"
    echo "4. 创建用户名密码"
    echo "5. 重启Squid服务"
    echo "6. 卸载Squid"
    echo "7. 退出"

    read -r choice

    case $choice in
        1) install_squid ;;
        2) backup_config ;;
        3) rewrite_config ;;
        4) create_user ;;
        5) restart_service ;;
        6) uninstall_squid ;;
        7) break ;;
        *) echo "无效的选项，请重新选择！" ;;
    esac

    echo
done
