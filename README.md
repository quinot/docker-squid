# Thomas' fork of `docker-squid`

This is my fork of a Docker container running a recent version of Squid, for the purpose of implementing parental control through a transparent filtering proxy.

Automated builds of the image are available on:

- DockerHub: [quinot/squid](https://hub.docker.com/r/quinot/squid)
  - ![Docker Image CI Status](https://github.com/quinot/docker-squid/workflows/Docker%20Image%20CI/badge.svg)

## Features

* Running Squid 5.8 and squidGuard 1.6.0 on a Debian stable system
* Using blacklists published by [Université de Toulouse](https://dsi.ut-capitole.fr/blacklists/)
* cron-based nightly refresh of blacklists
* Configured for transparent interception of HTTP and HTTPS traffic, with TLS splicing
* Lighttpd to serve squidGuard's blocked page CGI

## TBD

### Docker image

* TLS bumping (at least for intercepted pages)
* ssmtp for cron errors
* logging and reporting (SARG?)

### Local deployment

* L2 ipvlan traffic delivery
* Configuration of client ACL through RADIUS
* configuration & deployment with
  * docker-compose?
  * Ansible?
  * K8s (nah just kidding)

# Upstream below

# docker-squid

Docker Squid container based on Alpine Linux.


# Quick Start

Just launch container:

```bash
docker run -p 3128:3128 b4tman/squid
```

or use [docker-compose](https://docs.docker.com/compose/):

```bash
wget https://raw.githubusercontent.com/b4tman/docker-squid/master/docker-compose.yml
docker-compose up
```

# Configuration

## Environment variables:

- **SQUID_CONFIG_FILE**: Specify the configuration file for squid. Defaults to `/etc/squid/squid.conf`.

## Example:

```bash
docker run -p 3128:3128 \
	--env='SQUID_CONFIG_FILE=/etc/squid/my-squid.conf' \
	--volume=/srv/docker/squid/squid.conf:/etc/squid/my-squid.conf:ro \
	b4tman/squid
```

This will start a squid container with your config file `/srv/docker/squid/squid.conf`.
