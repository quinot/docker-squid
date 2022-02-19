#! /bin/sh

set -ex

/libexec/update-blacklists --use-cached-blacklists

service cron start

# Note: the pipe for squid's stdout must be created by user squid so that it can open /proc/self/fd/1 for writing
# hence the use of "|cat" (else the pipe is owned by root).
# Cf https://github.com/moby/moby/issues/31243#issuecomment-406879017

su -s /bin/sh squid -c "/usr/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -z && exec /usr/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -YCd 1 | cat"


