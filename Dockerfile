FROM debian:stable as build

ENV SQUID_VER 5.8

RUN set -x && \
	apt-get update && \
	apt-get install -y \
		gcc \
		g++ \
		libc-dev \
		curl \
		gnupg \
		libssl-dev \
		libperl-dev \
		autoconf \
		automake \
		make \
		libtool \
		libcap-dev

RUN set -x && \
	mkdir -p /tmp/build && \
	cd /tmp/build && \
	curl -SsL http://www.squid-cache.org/Versions/v${SQUID_VER%%.*}/squid-${SQUID_VER}.tar.gz -o squid-${SQUID_VER}.tar.gz && \
	curl -SsL http://www.squid-cache.org/Versions/v${SQUID_VER%%.*}/squid-${SQUID_VER}.tar.gz.asc -o squid-${SQUID_VER}.tar.gz.asc

COPY squid-keys.asc /tmp

RUN set -x && \
	cd /tmp/build && \
	export GNUPGHOME="$(mktemp -d)" && \
	gpg --import /tmp/squid-keys.asc && \
	gpg --batch --verify squid-${SQUID_VER}.tar.gz.asc squid-${SQUID_VER}.tar.gz && \
	rm -rf "$GNUPGHOME"

RUN set -x && \
	cd /tmp/build && \
	tar -xzf squid-${SQUID_VER}.tar.gz && \
        cd squid-${SQUID_VER} && \
	\
	CFLAGS="-g0 -O2" \
	CXXFLAGS="-g0 -O2" \
	LDFLAGS="-s" \
	\
	./configure \
		--build="$(uname -m)" \
		--host="$(uname -m)" \
		--prefix=/usr \
		--datadir=/usr/share/squid \
		--sysconfdir=/etc/squid \
		--libexecdir=/usr/lib/squid \
		--localstatedir=/var \
		--with-logdir=/var/log/squid \
		--disable-strict-error-checking \
		--disable-arch-native \
		--enable-removal-policies="lru,heap" \
		--enable-auth-digest \
		--enable-auth-basic="getpwnam,NCSA,DB" \
		--enable-basic-auth-helpers="DB" \
		--enable-epoll \
		--enable-external-acl-helpers="file_userip,unix_group,wbinfo_group" \
		--enable-auth-ntlm="fake" \
		--enable-auth-negotiate="wrapper" \
		--enable-silent-rules \
		--enable-delay-pools \
		--enable-arp-acl \
		--enable-openssl \
		--enable-ssl-crtd \
		--enable-security-cert-generators="file" \
		--enable-ident-lookups \
		--enable-useragent-log \
		--enable-cache-digests \
		--enable-referer-log \
		--enable-async-io \
		--enable-truncate \
		--enable-arp-acl \
		--enable-htcp \
		--enable-carp \
		--enable-epoll \
		--enable-follow-x-forwarded-for \
		--enable-storeio="diskd rock" \
		--enable-ipv6 \
		--enable-translation \
		--disable-snmp \
		--disable-dependency-tracking \
		--with-large-files \
		--with-default-user=proxy \
		--with-openssl \
		--with-pidfile=/var/run/squid/squid.pid && \
	make -j 8 && \
	make install && \
	cd tools/squidclient && make && make install-strip

RUN sed -i \
	-e '1i\
include /etc/squid/conf.d/*.conf' \
	-e '$a\
include /etc/squid/conf.d.tail/*.conf' \
	/etc/squid/squid.conf

FROM debian:stable

ENV SQUID_CONFIG_FILE /etc/squid/squid.conf
ENV SQUID_LOG_LEVEL 1
ENV TZ Europe/Moscow

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	cron \
	curl \
	iptables \
	libcap2 \
	libdb5.3 \
	libltdl7 \
	lighttpd \
	openssl \
	squidguard

COPY --from=build /etc/squid/ /etc/squid/
COPY --from=build /usr/lib/squid/ /usr/lib/squid/
COPY --from=build /usr/share/squid/ /usr/share/squid/
COPY --from=build /usr/sbin/squid /usr/sbin/squid
COPY --from=build /usr/bin/squidclient /usr/bin/squidclient

RUN install -d -o proxy -g proxy \
		/var/cache/squid \
		/var/log/squid \
		/var/run/squid && \
	chmod +x /usr/lib/squid/*

RUN install -d -m 755 -o proxy -g proxy \
		/etc/squid/conf.d \
		/etc/squid/conf.d.tail

RUN touch /etc/squid/conf.d/placeholder.conf

RUN lighty-enable-mod cgi && \
	install -m 755 -o root -g root -D /usr/share/doc/squidguard/examples/squidGuard-simple.cgi /usr/lib/cgi-bin/squidGuard.cgi

COPY files/ /

VOLUME /etc/squid/conf.d /var/lib/squidguard/db /var/cache/squid
EXPOSE 3128 3129 3130/tcp

ENTRYPOINT ["/libexec/entrypoint.sh"]
