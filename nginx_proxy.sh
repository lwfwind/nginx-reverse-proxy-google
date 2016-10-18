#! /bin/bash
SELF=$(cd $(dirname $0); pwd -P)/$(basename $0)
CURRENTDIR=$(cd $(dirname $0); pwd -P)
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear
echo -n "To be sure your system is Debian,please enter 'y/yes' to continue: "  
read key
if [ $key = "yes" ]||[ $key = "y" ];then
	echo -n "Set your domain for google search: " 
    read key
    DOMAIN=$key
    if [ ! $DOMAIN ];then
    	echo "Two domains should not be null OR the same! Error happens!"
    	exit 1
    else
    	echo "your google search domain is $DOMAIN"
    	echo -n "Enter any key to continue ... "
        read goodmood
    	echo 'Start installing!' 	
    fi
    
else
	exit 1
fi
#update  system
apt-get update
if [ $? -eq 0 ]; then
	echo "update success"
else
	apt-get update
fi
#install  dependency
apt-get install -y libpcre3 libpcre3-dev
if [ $? -eq 0 ]; then
	echo "libpcre3 libpcre3-dev installed"
else
	apt-get install -y libpcre3 libpcre3-dev
fi
apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
if [ $? -eq 0 ]; then
	echo "zlib1g zlib1g-dev openssl libssl-dev installed"
else
	apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
fi
apt-get install -y git gcc g++ make automake
if [ $? -eq 0 ]; then
	echo "gcc g++ make automake installed"
else
	apt-get install -y git gcc g++ make automake
fi

cd $CURRENTDIR
rm -rf /usr/share/nginx
rm -rf /etc/nginx
rm -rf /usr/sbin/nginx
#download  nginx-1.8.0
test -f nginx-1.6.2.tar.gz || wget -N http://nginx.org/download/nginx-1.6.2.tar.gz && tar -zxvf nginx-1.6.2.tar.gz

#download  ngx_http
test -d ngx_http_google_filter_module || git clone https://github.com/cuber/ngx_http_google_filter_module
test -d git ngx_http_substitutions_filter_module || clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module

#configure for nginx
cd nginx-1.6.2
./configure --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' --with-ld-opt=-Wl,-z,relro --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-pcre-jit --with-debug --with-http_addition_module --with-http_dav_module  --with-http_gzip_static_module  --with-http_realip_module --with-http_stub_status_module --with-http_ssl_module --with-http_sub_module --with-ipv6 --with-sha1=/usr/include/openssl --with-md5=/usr/include/openssl --with-mail --with-mail_ssl_module --with-http_sub_module \
--add-module=$CURRENTDIR/ngx_http_substitutions_filter_module \
--add-module=$CURRENTDIR/ngx_http_google_filter_module
#6.make && make install for nginx
make && make install
cp $CURRENTDIR/nginx-1.6.2/objs/nginx /usr/sbin/

cd $CURRENTDIR
rm -rf google
cp google_template google
sed -i "s#<domain.name>#$DOMAIN#g" google
sed -i "s#<ssl.crt>#$CURRENTDIR/ssl/server.crt#g" google
sed -i "s#<ssl.key>#$CURRENTDIR/ssl/server.key#g" google
test -d /etc/nginx/sites-enabled || mkdir -p /etc/nginx/sites-enabled
rm -rf /etc/nginx/nginx.conf
cp nginx.conf /etc/nginx/
cp google /etc/nginx/sites-enabled/

#systemctl
rm -rf /lib/systemd/system/nginx.service
systemctl unmask nginx
cp nginx.service /lib/systemd/system/
systemctl reload nginx
