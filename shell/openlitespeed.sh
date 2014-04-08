#!/bin/bash
#
# Author: Shuang.Ca <ylqjgm@gmail.com>
# Home: http://llnmp.com
# Blog: http://shuang.ca
#
# Version: Ver 0.4
# Created: 2014-03-31

useradd -M -s /sbin/nologin www
mkdir -p /home/wwwroot/default

[ ! -s $SRC_DIR/openlitespeed-1.3.tgz ] && wget -c $GET_URI/openlitespeed/openlitespeed-1.3.tgz -O $SRC_DIR/openlitespeed-1.3.tgz

cd $SRC_DIR
tar zxf openlitespeed-1.3.tgz
cd openlitespeed-1.3
./configure --prefix=/usr/local/lsws --with-user=www --with-group=www --with-admin=$webuser --with-password=$webpass --with-email=$webemail --enable-adminssl=no --enable-spdy
make -j $cpu_num && make install

sed -i 's/<vhRoot>\$SERVER_ROOT\/DEFAULT\/<\/vhRoot>/<vhRoot>\/home\/wwwroot\/default\/<\/vhRoot>/g' /usr/local/lsws/conf/httpd_config.xml
sed -i 's/<configFile>\$VH_ROOT\/conf\/vhconf\.xml<\/configFile>/<configFile>\$SERVER_ROOT\/conf\/default\.xml<\/configFile>/g' /usr/local/lsws/conf/httpd_config.xml
sed -i "s/<address>\*:8088<\/address>/<address>\*:$port<\/address>/g" /usr/local/lsws/conf/httpd_config.xml

cp $PWD_DIR/conf/vhconf.xml /usr/local/lsws/conf/default.xml
rm -rf /usr/local/lsws/DEFAULT/
mkdir -p /home/wwwlogs/litespeed
chown -R lsadm:lsadm /usr/local/lsws/admin/

service lsws restart