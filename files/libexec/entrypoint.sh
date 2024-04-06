#! /bin/sh

set -ex

# Network

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-ports 3129
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-ports 3130

# Start services

service cron start
service lighttpd start

# squidGuard

cd /etc/squidguard
rm -f squidGuard.conf
cat conf.d/* | m4 > squidGuard.conf

# Squid

ssl_dir=/etc/squid/ssl
install -o proxy -g proxy -m 0700 -d ${ssl_dir}
[ -f ${ssl_dir}/squid.key ] || openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/CN=squid-container" -keyout ${ssl_dir}/squid.key -out ${ssl_dir}/squid.crt
chown proxy:proxy /etc/squid/ssl/*

# Note: the pipe for squid's stdout must be created by user squid so that it can open /proc/self/fd/1 for writing
# hence the use of "|cat" (else the pipe is owned by root).
# Cf https://github.com/moby/moby/issues/31243#issuecomment-406879017

su -s /bin/sh proxy -c "/libexec/update-blacklists --boot; /usr/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -z && exec /usr/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -YC -d ${SQUID_LOG_LEVEL} | cat"


