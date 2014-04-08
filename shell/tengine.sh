#!/bin/bash
#
# Author: Shuang.Ca <ylqjgm@gmail.com>
# Home: http://llnmp.com
# Blog: http://shuang.ca
#
# Version: Ver 0.4
# Created: 2014-03-31

[ "$jemalloc_install" == "y" ] && COMMAND="--with-ld-opt='-ljemalloc'"

[ ! -s $SRC_DIR/tengine-2.0.2.tar.gz ] && wget -c $GET_URI/tengine/tengine-2.0.2.tar.gz -O $SRC_DIR/tengine-2.0.2.tar.gz

cd $SRC_DIR
tar zxf tengine-2.0.2.tar.gz
cd tengine-2.0.2

sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-http_concat_module=shared $COMMAND

make -j $cpu_num && make install

mkdir -p /home/wwwlogs/nginx /usr/local/nginx/conf/vhost
rm -f /usr/local/nginx/conf/nginx.conf

cat > /usr/local/nginx/conf/nginx.conf <<EOF
user www www;

worker_processes auto;
worker_cpu_affinity auto;

dso {
    load ngx_http_concat_module.so;
}

error_log /usr/local/nginx/logs/nginx_error.log crit;
pid /usr/local/nginx/nginx.pid;

worker_rlimit_nofile 51200;

events {
    use epoll;
    worker_connections 51200;
}

http {
    include mime.types;
    default_type application/octet-stream;

    server_names_hash_bucket_size 128;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 50m;

    sendfile on;
    tcp_nopush on;

    keepalive_timeout 60;

    tcp_nodelay on;

    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 256k;

    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml image/jpeg image/png image/gif;
    gzip_vary on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_disable "MSIE [1-6]\.";

    log_format access '\$remote_addr - \$remote_user [\$time_local] "\$request" '
        '\$status \$body_bytes_sent "\$http_referer" '
        '"\$http_user_agent" \$http_x_forwarded_for';
             
    include vhost/*.conf;
}
EOF

cat > /usr/local/nginx/conf/proxy.conf <<EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 32k;
proxy_busy_buffers_size 64k;
proxy_redirect http://127.0.0.1:8088/ /;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Host \$host;
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF

cat > /usr/local/nginx/conf/vhost/default.conf <<EOF
log_format default '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    '\$status \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" \$http_x_forwarded_for';

server {
    listen $IP:80;
    server_name shuang.ca;
    index index.html index.htm index.php;
    root /home/wwwroot/default;

    error_log /home/wwwlogs/nginx/default_error.log;
    access_log /home/wwwlogs/nginx/default_access.log;

    location / {
        try_files \$uri @litespeed;
    }

    location @litespeed {
        internal;
        proxy_pass http://127.0.0.1:8088;
        include proxy.conf;
    }

    location ~ .*\.(php|php5)?$ {
        proxy_pass http://127.0.0.1:8088;
        include proxy.conf;
    }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
        expires 30d;
    }

    location ~ .*\.(js|css)?$ {
        expires 12h;
    }
}
EOF

bit=$(getconf LONG_BIT)
if [ "$bit" == "64" ]; then
    ln -s /usr/local/lib/libpcre.so.1 /lib64
else
    ln -s /lib/libpcre.so.0.0.1 /lib/libpcre.so.1
fi

cp $PWD_DIR/conf/nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
chkconfig --add nginx
chkconfig nginx on

service lsws restart
service nginx start
