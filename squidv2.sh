#!/bin/bash

# 安装Squid
install_squid() {
    echo "开始安装Squid..."
    yum update -y
    yum install -y squid
    echo "Squid安装完成！"
}

# 配置Squid
configure_squid() {
    echo "开始配置Squid..."
    # 备份默认配置文件
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

    # 修改Squid配置文件
    sed -i 's/#cache_log \/var\/log\/squid\/cache.log/cache_log \/var\/log\/squid\/access.log squid auth/g' /etc/squid/squid.conf
    echo "auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd" >> /etc/squid/squid.conf
    echo "auth_param basic children 5" >> /etc/squid/squid.conf
    echo "auth_param basic realm Squid proxy-caching web server" >> /etc/squid/squid.conf
    echo "auth_param basic credentialsttl 2 hours" >> /etc/squid/squid.conf
    echo "auth_param basic casesensitive off" >> /etc/squid/squid.conf
    echo "acl authenticated proxy_auth REQUIRED" >> /etc/squid/squid.conf
    echo "http_access allow authenticated" >> /etc/squid/squid.conf

    # 创建用户名和密码文件
    create_password_file

    # 设置Squid为自启动
    systemctl enable squid

    echo "Squid配置完成！"
}

# 创建用户名和密码文件
create_password_file() {
    echo "请输入用户名："
    read -r username
    echo "请输入密码："
    read -rs password
    htpasswd -b -c /etc/squid/passwd "$username" "$password"
    echo "用户名和密码已创建！"
}

# 还原默认配置文件
restore_default_config() {
    echo "还原默认配置文件..."
    cp /etc/squid/squid.conf.bak /etc/squid/squid.conf
    echo "默认配置文件已还原！"
}

# 启动Squid
start_squid() {
    echo "启动Squid..."
    systemctl start squid
    echo "Squid已启动！"
}

# 停止Squid
stop_squid() {
    echo "停止Squid..."
    systemctl stop squid
    echo "Squid已停止！"
}

# 卸载Squid
uninstall_squid() {
    echo "开始卸载Squid..."
    systemctl stop squid
    yum remove -y squid
    rm -rf /etc/squid
    echo "Squid卸载完成！"
}

# 查看访问日志
view_access_log() {
    echo "访问日志内容："
    cat /var/log/squid/access.log
}

# 脚本入口
main() {
    echo "欢迎使用Squid多IP版一键搭建脚本！"
    echo "请选择操作："
    echo "1. 安装Squid"
    echo "2. 配置Squid"
    echo "3. 修改密码"
    echo "4. 还原默认配置文件"
    echo "5. 启动Squid"
    echo "6. 停止Squid"
    echo "7. 卸载Squid"
    echo "8. 查看访问日志"
    echo "9. 退出"

    read -p "请输入操作编号：" choice

    case $choice in
        1)
            install_squid
            ;;
        2)
            configure_squid
            ;;
        3)
            create_password_file
            ;;
        4)
            restore_default_config
            ;;
        5)
            start_squid
            ;;
        6)
            stop_squid
            ;;
        7)
            uninstall_squid
            ;;
        8)
            view_access_log
            ;;
        9)
            exit 0
            ;;
        *)
            echo "无效的操作编号！"
            ;;
    esac

    main
}

# 执行脚本
main