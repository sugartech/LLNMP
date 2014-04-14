#!/bin/bash
#
# Author: Shuang.Ca <ylqjgm@gmail.com>
# Home: http://llnmp.com
# Blog: http://shuang.ca
#
# Version: Ver 0.4
# Created: 2014-02-07
# Updated: 2014-03-31
# Changed: 安装选项调整, 模块化安装
# Updated: 2014-04-12
# Changed: 更新LiteSpeed到4.2.9版本
# Updated: 2014-04-13
# Changed: 更新缓存组件选择, 去除eAccelerator

#define var
VERSION="0.4"
PWD_DIR=`pwd`
SRC_DIR=$PWD_DIR/src
SH_DIR=$PWD_DIR/shell
LOG_FILE=$PWD_DIR/install.log
GET_URI="http://soft.shuang.ca"

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

#check if user is not root
if [ $(id -u ) != "0" ]; then
    echo -e "\033[31mError: You must be root to run this script, Please use root to install llnmp!\033[0m"
    exit 1
fi

clear
echo "====================================================================="
echo -e "\033[32mLLNMP V$VERSION for CentOS/RedHat, Debian, Ubuntu Linux VPS Written by Shuang.Ca\033[0m"
echo "====================================================================="
echo -e "\033[32mA tool to auto-compile & install LiteSpeed(OpenLiteSpeed)+MySQL(MariaDB)+PHP on Linux\033[0m"
echo ""
echo -e "\033[32mFor more information please visit http://llnmp.com/ or http://shuang.ca/\033[0m"
echo "====================================================================="

#check main ip address
IP=`ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{print $1}' | sed 1q`
while :
do
    read -p "Is $IP your main ip?[y/n]: " right_ip
    if [ "$right_ip" != "y" -a "$right_ip" != "n" ]; then
        echo -e "\033[31mInput error! Please only input y or n\033[0m"
    fi

    [ "$right_ip" == "y" ] && break

    if [ "$right_ip" == "n" ]; then
        read -p "Please input your main ip: " new_ip
        IP=$new_ip
        [ ! -z "$IP" ] && break
    fi
done

#select web server
if [ -f /etc/redhat-release ]; then
    centosversion=$(cat /etc/redhat-release | grep -o [0-9] | sed 1q)
    if [ "$centosversion" == "5" ]; then
        webecho="LiteSpeed 4.2.9Std"
    else
        echo "Please select a web server:"
        echo -e "\t\033[32m1\033[0m. Install LiteSpeed 4.2.9Std"
        echo -e "\t\033[32m2\033[0m. Install OpenLiteSpeed 1.3"
        read -p "(Default LiteSpeed 4.2.9Std): " web_select

        if [ "$web_select" != 1 -a "$web_select" != 2 ]; then
            web_select=1
        fi

        [ "$web_select" == 1 ] && webecho="LiteSpeed 4.2.9Std"
        [ "$web_select" == 2 ] && webecho="OpenLiteSpeed 1.3"

        echo -e "\033[32m$webecho already installed!\033[0m"
    fi
else
    echo "Please select a web server:"
    echo -e "\t\033[32m1\033[0m. Install LiteSpeed 4.2.9Std"
    echo -e "\t\033[32m2\033[0m. Install OpenLiteSpeed 1.3"
    read -p "(Default LiteSpeed 4.2.7Std): " web_select

    if [ "$web_select" != 1 -a "$web_select" != 2 ]; then
        web_select=1
    fi

    [ "$web_select" == 1 ] && webecho="LiteSpeed 4.2.9Std"
    [ "$web_select" == 2 ] && webecho="OpenLiteSpeed 1.3"

    echo -e "\033[32m$webecho already installed!\033[0m"
fi

#set litespeed user name
echo "Please input the user name of $webecho:"
read -p "(Default user name: admin): " webuser
[ -z "$webuser" ] && webuser="admin"
echo -e "\033[32m$webecho user name: $webuser\033[0m"

#set litespeed user password
echo "Please input the user password of $webecho:"
read -p "(Default user password: llnmp.com): " webpass
[ -z "$webpass" ] && webpass="llnmp.com"
echo -e "\033[32m$webecho user password: $webpass\033[0m"

#set admin email
echo "Please input the admin email of $webecho:"
read -p "(Default admin email: root@localhost): " webemail
[ -z "$webemail" ] && webemail="root@localhost"
echo -e "\033[32m$webecho admin email: $webemail\033[0m"

#install nginx
read -p "Do you want install Nginx or Tengine?(Default y) [y/n]: " nginx_install

if [ "$nginx_install" != "y" -a "$nginx_install" != "n" ]; then
    nginx_install="y"
fi

if [ "$nginx_install" == "y" ]; then
    echo "Please select Nginx or Tengine:"
    echo -e "\t\033[32m1\033[0m. Install Nginx 1.4.7"
    echo -e "\t\033[32m2\033[0m. Install Tengine 2.0.2"
    read -p "(Default Nginx 1.4.6): " nginx_select

    if [ "$nginx_select" != 1 -a "$nginx_select" != 2 ]; then
        nginx_select=1
    fi

    [ "$nginx_select" == 1 ] && nginxecho="Nginx 1.4.7"
    [ "$nginx_select" == 2 ] && nginxecho="Tengine 2.0.2"

    echo -e "\033[32m$nginxecho already installed!\033[0m"
fi

#select database server
echo "Please select a Database Server:"
echo -e "\t\033[32m1\033[0m. Install MySQL 5.5.37"
echo -e "\t\033[32m2\033[0m. Install MariaDB 5.5.36"
read -p "(Default MySQL 5.5.35): " db_select

if [ "$db_select" != 1 -a "$db_select" != 2 ]; then
    db_select=1
fi


[ "$db_select" == 1 ] && dbecho="MySQL 5.5.37"
[ "$db_select" == 2 ] && dbecho="MariaDB 5.5.36"

echo -e "\033[32m$dbecho already installed!\033[0m"

#set mysql root password
echo "Please input the root password of $dbecho:"
read -p "(Default root password: llnmp.com): " dbpass
[ -z "$dbpass" ] && dbpass="llnmp.com"
echo -e "\033[32m$dbecho root password: $dbpass\033[0m"

#select php version
echo "Please select a PHP Version:"
echo -e "\t\033[32m1\033[0m. Install PHP 5.2.17"
echo -e "\t\033[32m2\033[0m. Install PHP 5.3.28"
echo -e "\t\033[32m3\033[0m. Install PHP 5.4.26"
echo -e "\t\033[32m4\033[0m. Install PHP 5.5.10"
read -p "(Default PHP 5.3.28): " php_select

if [ "$php_select" != 1 -a "$php_select" != 2 -a "$php_select" != 3 -a "$php_select" != 4 ]; then
    php_select=2
fi

[ "$php_select" == 1 ] && phpecho="PHP 5.2.17"
[ "$php_select" == 2 ] && phpecho="PHP 5.3.28"
[ "$php_select" == 3 ] && phpecho="PHP 5.4.26"
[ "$php_select" == 4 ] && phpecho="PHP 5.5.10"

echo -e "\033[32m$phpecho already installed!\033[0m"

#select cache
read -p "Do you want install cache of PHP?(Default y) [y/n]: " cache_install

if [ "$cache_install" != "y" -a "$cache_install" != "n" ]; then
    cache_install="y"
fi

if [ "$cache_install" == "y" ]; then
    echo "Please select a opcode cache of the PHP:"
    echo -e "\t\033[32m1\033[0m. Install Zend Opcache 7.0.3"
    echo -e "\t\033[32m2\033[0m. Install APCU 4.0.4"
    echo -e "\t\033[32m3\033[0m. Install XCache 3.1.0"
    read -p "Please input a number 1,2,3(Default 1): " cache_select

    if [ "$cache_select" != 1 -a "$cache_select" != 2 -a "$cache_select" != 3 ]; then
        cache_select=1
    fi

    if [ "$cache_select" == '3' ]; then
        while :
        do
            read -p "Please input xcache admin password: " xcachepass
            (( ${#xcachepass} >= 5 )) && xcachepass=`echo -n "$xcachepass" | md5sum | awk '{print $1}'` && break || echo -e "\033[31mxcache admin password least 5 characters!\033[0m"
        done
    fi

    [ "$cache_select" == 1 ] && echo -e "\033[32mZend Opcache 7.0.3 already installed!\033[0m"
    [ "$cache_select" == 2 ] && echo -e "\033[32mAPCU 4.0.4 already installed!\033[0m"
    [ "$cache_select" == 3 ] && echo -e "\033[32mXCache 3.1.0 already installed!\033[0m"

    [ "$php_select" == 1 ] && zendecho="Zend Optimizer" || zendecho="Zend GuardLoader"
    read -p "Do you want install $zendecho?(Default y)[y/n]: " zend_install

    if [ "$zend_install" != "y" -a "$zend_install" != "n" ]; then
        zend_install="y"
    fi

    [ "$zend_install" == "y" ] && echo -e "\033[32m$zendecho already installed!\033[0m"
fi

#install redis
read -p "Do you want install redis?(Default y) [y/n]: " redis_install

if [ "$redis_install" != "y" -a "$redis_install" != "n" ]; then
    redis_install="y"
fi

[ "$redis_install" == "y" ] && echo -e "\033[32mRedis 2.8.8 already installed!\033[0m"

#install memcache
read -p "Do you want install memcached?(Default y) [y/n]: " memcache_install

if [ "$memcache_install" != "y" -a "$memcache_install" != "n" ]; then
    memcache_install="y"
fi

[ "$memcache_install" == "y" ] && echo -e "\033[32mMemcached 1.4.17 already installed!\033[0m"

#install jemalloc
read -p "Do you want to use jemalloc optimize Database and Web server?(Default y) [y/n]: " jemalloc_install

if [ "$jemalloc_install" != "y" -a "$jemalloc_install" != "n" ]; then
    jemalloc_install="y"
fi

[ "$jemalloc_install" == "y" ] && echo -e "\033[32mjemalloc 3.5.1 already installed!\033[0m"

#install pureftpd
read -p "Do you want install Pureftpd?(Default y) [y/n]: " pureftpd_install

if [ "$pureftpd_install" != "y" -a "$pureftpd_install" != "n" ]; then
    pureftpd_install="y"
fi

if [ "$pureftpd_install" == "y" ]; then
    echo "Please input password of User manager:"
    read -p "(Default password: llnmp.com): " ftpmanagerpwd
    [ -z "$ftpmanagerpwd" ] && ftpmanagerpwd="llnmp.com"

    echo "Please input password of mysql ftp user:"
    read -p "(Default password: llnmp.com): " mysqlftppwd
    [ -z "$mysqlftppwd" ] && mysqlftppwd="llnmp.com"

    echo -e "\033[32mPureftpd 1.0.36 already installed!\033[0m"
fi

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

echo ""
echo "Press any key to start... or Press Ctrl+c to cancel"
char=`get_char`

mkdir -p $SRC_DIR /home/wwwroot/default /home/wwwlogs

chmod +x $PWD_DIR/init/*.sh
chmod +x $SH_DIR/*.sh

cpu_num=`cat /proc/cpuinfo | grep processor | wc -l`

#init
if [ -f /etc/redhat-release ]; then
    . $PWD_DIR/init/centos.sh 2>&1 | tee -a $LOG_FILE
elif [ ! -z "`cat /etc/issue | grep bian`" ]; then
    . $PWD_DIR/init/debian.sh 2>&1 | tee -a $LOG_FILE
elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ]; then
    . $PWD_DIR/init/ubuntu.sh 2>&1 | tee -a $LOG_FILE
else
    echo -e "\033[31mDoes not support this OS, Please reinstall Centos,Debian,Ubuntu! \033[0m"
    exit 1
fi

#jemalloc
if [ "$jemalloc_install" == "y" ]; then
    . $SH_DIR/jemalloc.sh 2>&1 | tee -a $LOG_FILE
fi

#database
if [ "$db_select" == 2 ]; then
    . $SH_DIR/mariadb.sh 2>&1 | tee -a $LOG_FILE
else
    . $SH_DIR/mysql.sh 2>&1 | tee -a $LOG_FILE
fi

#litespeed
if [ "$web_select" == 2 ]; then
    . $SH_DIR/openlitespeed.sh 2>&1 | tee -a $LOG_FILE
else
    . $SH_DIR/litespeed.sh 2>&1 | tee -a $LOG_FILE
fi

#nginx
if [ "$nginx_install" == "y" ]; then
    [ "$nginx_select" == 1 ] && . $SH_DIR/nginx.sh 2>&1 | tee -a $LOG_FILE
    [ "$nginx_select" == 2 ] && . $SH_DIR/tengine.sh 2>&1 | tee -a $LOG_FILE
fi

#php
if [ "$php_select" == 1 ]; then
    . $SH_DIR/php52.sh 2>&1 | tee -a $LOG_FILE
elif [ "$php_select" == 3 ]; then
    . $SH_DIR/php54.sh 2>&1 | tee -a $LOG_FILE
elif [ "$php_select" == 4 ]; then
    . $SH_DIR/php55.sh 2>&1 | tee -a $LOG_FILE
else
    . $SH_DIR/php53.sh 2>&1 | tee -a $LOG_FILE
fi

#redis
if [ "$redis_install" == "y" ]; then
    . $SH_DIR/redis.sh 2>&1 | tee -a $LOG_FILE
fi

#memcache
if [ "$memcache_install" == "y" ]; then
    . $SH_DIR/memcached.sh 2>&1 | tee -a $LOG_FILE
fi

#cache
if [ "$cache_install" == "y" ]; then
    [ "$cache_select" == 1 ] && . $SH_DIR/zendopcache.sh 2>&1 | tee -a $LOG_FILE
    [ "$cache_select" == 2 ] && . $SH_DIR/apcu.sh 2>&1 | tee -a $LOG_FILE
    [ "$cache_select" == 3 ] && . $SH_DIR/xcache.sh 2>&1 | tee -a $LOG_FILE
fi

#zend
if [ "$zend_install" == "y" ]; then
    . $SH_DIR/zend.sh 2>&1 | tee -a $LOG_FILE
fi

#pureftpd
if [ "$pureftpd_install" == "y" ]; then
    . $SH_DIR/pureftpd.sh 2>&1 | tee -a $LOG_FILE
fi

#web
. $SH_DIR/web.sh 2>&1 | tee -a $LOG_FILE

#check litespeed
[ -s /usr/local/lsws ] && service lsws restart
[ -s /usr/local/nginx ] && service nginx restart
[ -s /usr/local/mysql ] && service mysqld restart
[ -s /usr/local/redis ] && service redis restart
[ -s /usr/local/memcached ] && service memcached restart
[ -s /usr/local/pureftpd ] && service pureftpd restart

echo "====================================================================="
echo -e "\033[32mLLNMP V$VERSION for CentOS/RedHat, Debian, Ubuntu Linux VPS Written by Shuang.Ca\033[0m"
echo "====================================================================="
echo ""
echo "For more information please visit http://llnmp.com/ or http://shuang.ca/"
echo ""
echo "$webecho admin name: $webuser"
echo "$webecho admin password: $webpass"
echo "$dbecho root password: $dbpass"
echo ""
echo "$webecho control panel: http://$IP:7080"
echo "phpMyAdmin: http://$IP/phpmyadmin/"
echo "Prober: http://$IP/p.php"
echo ""
echo "The path of some dirs:"
echo "$webecho: /usr/local/lsws"
if [ "$nginx_install" == "y" ]; then
    echo "$nginxecho: /usr/local/nginx"
fi
echo "$dbecho: /usr/local/mysql"
echo "PHP: /usr/local/lsws/lsphp5/bin/php"
echo "Web: /home/wwwroot"
echo ""
echo "====================================================================="
