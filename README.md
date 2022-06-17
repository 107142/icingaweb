This repository contains source for the [Docker](https://www.docker.com/) image of the [Icinga](https://www.icinga.org/) monitoring solution web frontend.

**Contains only container for Icingaweb. Icinga core is in a separate [repository](https://gitlab.ics.muni.cz/monitoring/icinga).**

**For production use `stable` tag or [version](https://gitlab.ics.muni.cz/monitoring/icingaweb/container_registry/) specific tag.**

**You can also have a look at the [releases page](https://gitlab.ics.muni.cz/monitoring/icingaweb/-/releases).**

Docker image: [registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable](registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable)

[[_TOC_]]

# Icingaweb Docker

## Image details

1.  Based on Debian Bullseye
2.  Key features:
    *  icingacli
    *  icingaweb2
        *  [icingaweb2-director](https://github.com/Icinga/icingaweb2-module-director)
        *  [icingaweb2-graphite](https://github.com/Icinga/icingaweb2-module-graphite)
        *  [icingaweb2-grafana](https://github.com/Mikesch-mp/icingaweb2-module-grafana)
        *  [icingaweb2-businessprocess](https://github.com/Icinga/icingaweb2-module-businessprocess)
        *  [icingaweb2-dependency](https://github.com/visgence/icinga2-dependency-module)
        *  [icingaweb2-vsphere](https://github.com/Icinga/icingaweb2-module-vsphere)
        *  [icingaweb2-map](https://github.com/nbuchwitz/icingaweb2-module-map)
        *  [icingaweb2-globe](https://github.com/Mikesch-mp/icingaweb2-module-globe)
        *  [icingaweb2-puppetdb](https://github.com/Icinga/icingaweb2-module-puppetdb)
        *  [icingaweb2-incubator](https://github.com/Icinga/icingaweb2-module-incubator)
    *  Supervisor
    *  Apache2
    *  PHP-FPM
    *  OpenID Connect
    *  TLS support
    *  Custom CA support
    *  Custom plugin support
    *  Custom script support
    *  Apache vHost
3.  Without integrated database. Use official PostgreSQL image. MariaDB is not supported.
4.  Without Icinga monitoring core. Use separate [image](https://gitlab.ics.muni.cz/monitoring/icinga)
5.  Without SSH. Use `docker exec` or `nsenter`

## Stability

This project is mainly designed for [Insitute of Computer Science](https://ics.muni.cz) of Masaryk university. It is tested and runs in a production environment. However since I lack sufficient resources to properly test every module and feature and prioritize those relevant to my needs it is possible some bugs may still be present.

## Development

This project is for the time being considered feature complete and I won't be implementing any additional features. I will however continue updating the image and fix any issues should they arise.

## Usage

This project assumes you have intermediate knowledge of Docker, networking, GNU/Linux and Icinga. This documentation is by no means a step-by-step guide.

#### Quick start using docker run

Start of a new container on port 80 of the running host. First command creates network, second runs database container, third icinga core and last runs Icingaweb.  
```console
docker network create --ipv6 --driver=bridge --subnet=fd00:dead:beef::/48 icinet
docker run -d -e POSTGRES_PASSWORD=sec-pwd --net=icinet --name pgsql --hostname=pgsql postgres:13
docker run -d -p 5665:5665 --ulimit nofile=65536:65536 -e PGSQL_ROOT_PASS=sec-pwd -e DEFAULT_PGSQL_PASS=sec-pwd --net=icinet --name icinga2 --hostname=icinga2 registry.gitlab.ics.muni.cz:443/monitoring/icinga:stable
docker run -p 80:80 -e PGSQL_ROOT_PASS=sec-pwd -e DEFAULT_PGSQL_PASS=sec-pwd --net=icinet --name icingaweb2 --hostname=icingaweb2 -it registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```
Reachable at http://localhost/icingaweb2/ with credentials printed on screen during container start.

#### Docker-compose

Example configuration for [docker-compose](https://docs.docker.com/compose/) in `docker-compose.yml` file.  
Will start Icinga(web)2 containers with PostgreSQL container.  
```console
git clone git@gitlab.ics.muni.cz:monitoring/icingaweb.git
docker-compose up
```

Reachable at http://localhost/icingaweb2/ with credentials printed on screen during container start.

#### Configuration

Configuration can be found in `/etc/icinga2` and `/etc/icingaweb2`. For persistent configuration directories have to be mounted as volumes.

For IPv6 conenctivity you can either use Docker NAT with [ip6tables](https://docs.docker.com/engine/reference/commandline/dockerd/) or need to define correct subnet and use [NDP](https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol).

#### Icinga connection

Container has to be able to connect to Icinga monitoring core. For this purpose API transport is used which connects to the Icinga core. Connection to IDO database is also required. This can be set using environment variables. See section *Icingaweb 2* and list of *environment variables at the end of this doc*.


# Icingaweb

Icingaweb is available at http://localhost/icingaweb2/ with credentials *admin:icinga* (unless set through environment variables).  
Icingaweb communicates with Icinga daemon via API transport with credentials *icinga2-transport:icingatransport* (unless set through environment variables).  
When using persistent volume `/etc/icingaweb2` environment variables `ICINGAWEB2_ADMIN_USER` and `ICINGAWEB2_ADMIN_PASS` need to be set.

Variables for API transport (default values in parenthesis):

 * `ICINGAWEB2_API_TRANSPORT_HOST` Hostname of icinga2 daemon (*icinga2*)
 * `ICINGAWEB2_API_TRANSPORT_PORT` API port (*5665*)
 * `ICINGAWEB2_API_TRANSPORT_USER` API user (*icinga2-transport*)
 * `ICINGAWEB2_API_TRANSPORT_PASS` API password (*icingatransport*)

## Apache2

Apache is configured automatically. In production it makes sense to set some variables (where applicable):

 * `APACHE2_SERVER_NAME` set *ServerName* directive - usually the FQDN of the machine running the webserver
 * `APACHE2_SERVER_ALIAS` set  *ServerAlias*
 * `APACHE2_SERVER_ADMIN` set *ServerAdmin*
 * `APACHE2_CSP` set *Content-Security-Policy* headers

## Saving PHP sessions

In case you want to save PHP sessions mount a volume `/var/lib/php/sessions/` inside the container. Session files are saved there.

Example:  
```console
docker run [...] -v $PWD/icingaweb2-sessions:/var/lib/php/sessions/ registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```

## PHP-FPM

In default state PHP-FPM is enabled with HTTP/2 protocol included. State is controlled via variable `ICINGAWEB2_FEATURE_PHP_FPM`.  
Environment variables controlling FPM can be found in [Reference](README.md#reference) section.


# Grafana

Grafana is not part of the container. To use the module you need to have Grafana instance ready. Configuration (default values in parenthesis):

 * `ICINGAWEB2_GRAFANA`: allows module usage (`false`)
 * `ICINGAWEB2_GRAFANA_HOST`: Grafana host (`grafana`)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARD`: default dashboard (*unset*)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDUID`: dashboard ID (*unset*)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDPANELID`: default pannel (*unset*)
 * `ICINGAWEB2_GRAFANA_PROXY_AUTHENTICATION`: access type (`token`)
 * `ICINGAWEB2_GRAFANA_PROXY_APITOKEN`: API token (*unset*)

Environment variables controlling the module can be found in [Reference](README.md#reference) section.


# Graphite

Graphite is not part of the container. Writer can be enabled with variable `ICINGAWEB2_FEATURE_GRAPHITE` set to `true` (or `1`) and setting URL in `ICINGAWEB2_FEATURE_GRAPHITE_URL`.

Example:
```console
docker run -t \
  --net=icinet  \
  -e ICINGAWEB2_FEATURE_GRAPHITE=true \
  -e ICINGAWEB2_FEATURE_GRAPHITE_URL=https://graphite.ics.muni.cz/ \
  registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```


# Icinga Director

[Icinga Director](https://github.com/Icinga/icingaweb2-module-director) module is by default enabled. Communicates with Icinga daemon via API transport. Configuration via environment variables (see [Reference](README.md#reference) section).

Dicrector is using Icinga API and Icinga endpoint, which is most of the time specified via FQDN. To make sure Docker correctly sends the network traffic to the correct container you should avoid using identical hostnames (*--hostname* switch). FQDN should be assigned to Icinga core when running on the same machine or multiple FQDN should be used (for Icinga and Icingaweb).

To disable the director set `ICINGAWEB2_FEATURE_DIRECTOR` to `false`.


# TLS support

To enable TLS, mount directory containing the certificates to `/etc/apache2/ssl/icinga`. Certificates must have the following names:
 * `icinga2.chain`: certificate chain (or single certificate)
 * `icinga2.key`: private key

To use Let's Encrypt certificates mount directory `/etc/letsencrypt` inside the container on `/etc/letsencrypt`. *Internal script assumes there is only a single domain name in `live` directory*.  
To regenerate certificate with CertBot mount your webroot directory to `/var/www` inside the container.

To set HTTPS redirection or HTTP/HTTPS dual-stack consult `APACHE2_HTTP` variable in [Reference](README.md#reference) section.


# Custom CA support

In case you want to use self-signed certificates or add other CA, add their respective certificate as `.crt` files in a directory mounted on `/usr/local/share/ca-certificates` inside the container.

Any CA's with `.crt` extension in this volume will be automatically added to the CA store at startup.


# Custom modules

To use custom modules install them in directory `enabledModules` in volume `/etc/icingaweb2`


# Custom script

At container start-up you can execute your own script. To execute mount your script into `/opt/custom_run` file.
Script will run before other any container components.


# Custom Apache vHost

To add your own vHost to Apache configuration mount your configuration file to `/etc/apache2/sites-available/custom_vhosts.conf` inside the container.


# External PostgreSQL database

Container does not have a database server and requires usage of a postgres container or an external database.

To conenct to external database use environment variables. For each database Icingaweb uses the is a set of variables configuring that particular connection. It is therefore possible to distribute various databases accross several hosts.

Variables are combination of service name and property with following format:

`<SERVICE>_PGSQL_<PROPERTY>`, where
 * `<SERVICE>` possible values: `ICINGAWEB2_IDO`, `ICINGAWEB2`, `ICINGAWEB2_DIRECTOR`, `ICINGAWEB2_DEPENDENCY`
 * `<PROPERTY>` posible values: `HOST`, `PORT`, `DATA`, `USER`, `PASS`, `SSL`, `SSL_KEY`, `SSL_CERT`, `SSL_CA`, `CHARSET`

For default values the `DEFAULT` variable is being sourced:

 * `DEFAULT_PGSQL_HOST`: database host (default `pgsql`). This values will be used for services requiring a database, unless you explicitly specifiy a different value for specific service
 * `DEFAULT_PGSQL_PORT`: database port (default 5432)
 * `DEFAULT_PGSQL_DATA`: database name (*unset*, specific services have separate databases)
    * `ICINGAWEB2_IDO_PGSQL_DATA`: Icinga IDO database name (default `icinga2_ido`)
    * `ICINGAWEB2_PGSQL_DATA`:  Icingaweb database name (default `icingaweb2`)
    * `ICINGAWEB2_DIRECTOR_PGSQL_DATA`: Icinga Director database name (default `icingaweb2_director`)
    * `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`: Icingaweb Dependency database name (default `icinga2_dependencies`)
 * `DEFAULT_PGSQL_USER`: PostgreSQL user (default `icinga2`)
 * `DEFAULT_PGSQL_PASS`: PostgreSQL pass (default *random*)

## PostgreSQL TLS

*By default TLS is disabled*. To connect to database using well-known CA just set `ICINGAWEB2_PGSQL_SSL` to `1`. To use your own CA or authenticate with certificates you have to mount those inside the container.

## Creating databases and tables

In order to create relevant databases, tables and schemas you have to set superuser variables for PostgreSQL:

 * `PGSQL_ROOT_USER`: superuser (default `postgres`)
 * `PGSQL_ROOT_PASS`: password (default *unset*)

Should the value for `PGSQL_ROOT_PASS` be left unset database and table creation will be skipped. It is therefore possible to unset the variables after creating all databases. You can also prepare the database [manually](https://icinga.com/docs/icinga-2/latest/doc/02-installation/#setting-up-the-postgresql-database).


# Dependency module

Configured via environment variables. Disabled by default. Module requires access to API transport. Variables (default value in parenthesis):

 * `ICINGAWEB2_DEPENDENCY`: enable module (`false`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_HOST`: database host (`DEFAULT_PGSQL_HOST`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_PORT`: database port (`DEFAULT_PGSQL_PORT`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_USER`: database user (`DEFAULT_PGSQL_USER`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_PASS`: database pass (`DEFAULT_PGSQL_PASS`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`: database name (`icinga2_dependencies`)
 * `ICINGAWEB2_DEPENDENCY_HOST`: Icinga API transport (`ICINGAWEB2_API_TRANSPORT_HOST`)
 * `ICINGAWEB2_DEPENDENCY_PORT`: Icinga API port (`ICINGAWEB2_API_TRANSPORT_PORT`)
 * `ICINGAWEB2_DEPENDENCY_USER`: Icinga API user (`ICINGAWEB2_API_TRANSPORT_USER`)
 * `ICINGAWEB2_DEPENDENCY_PASS`: Icinga API password (`ICINGAWEB2_API_TRANSPORT_PASS`)


# Business process

Enabled by default:

  * `ICINGAWEB2_BUSSINESS`: enables module (`true`)


# Map

Disable by default:

 * `ICINGAWEB2_MAP`: enables module (`false`)


# OpenID Connect

Enabled with `APACHE2_OIDC_ENABLE` variable.

To successfully use the module variables `APACHE2_OIDC_CLIENTID`, `APACHE2_OIDC_CLIENTSECRET`, `APACHE2_OIDC_REMOTE_USER_CLAIM` and `APACHE2_OIDC_METADATA` need to be set.

Icingaweb itself does not support federated identity, it is not possible to source groups, user attributes or other values. This works strictly as an SSO and supplies usernames via `REMOTE_USER` header. Groups need to be sourced either from LDAP or a local database.


# Logging

Logging can be set with Docker [driver](https://docs.docker.com/config/containers/logging/configure/).

By default you can show logs with dommand `docker logs icingaweb`.


# Reference

## Environment variables

| Variable               | Default value | Description     |
| ---------------------- | ------------- | -----------     |
| `ICINGAWEB2_API_TRANSPORT_HOST` | icinga2 | Host running icinga2 daemon with API enabled |
| `ICINGAWEB2_API_TRANSPORT_PORT` | 5665 | API port |
| `ICINGAWEB2_API_TRANSPORT_USER` | icinga2-transport | Icinga API user   |
| `ICINGAWEB2_API_TRANSPORT_PASS` | icingatransport | Icinga API password |
| `PGSQL_ROOT_USER` | postgres | Superuser PostgreSQL |
| `PGSQL_ROOT_PASS` | *unset* | Superuser PostgreSQL password |
| `DEFAULT_PGSQL_USER` | icinga2 | Default user for databases |
| `DEFAULT_PGSQL_PASS` | *random* | Default password |
| `DEFAULT_PGSQL_HOST` | pgsql | Default database host |
| `DEFAULT_PGSQL_PORT` | 5432 | Default database port |
| `ICINGAWEB2_LOGGING_LEVEL` | ERROR | Log level |
| `ICINGAWEB2_IDO_PGSQL_HOST` | Sources `DEFAULT_PGSQL_HOST` | PostgreSQL host for IDO |
| `ICINGAWEB2_IDO_PGSQL_PORT` | Sources `DEFAULT_PGSQL_PORT` | PostgreSQL port for IDO |
| `ICINGAWEB2_IDO_PGSQL_USER` | Sources `DEFAULT_PGSQL_USER` | PostgreSQL user for IDO |
| `ICINGAWEB2_IDO_PGSQL_PASS` | Sources `DEFAULT_PGSQL_PASS` | PostgreSQL password for IDO |
| `ICINGAWEB2_IDO_PGSQL_DATA` | icinga2_ido | PostgreSQL database name for IDO |
| `ICINGAWEB2_IDO_PGSQL_SSL` | 0 | TLS |
| `ICINGAWEB2_IDO_PGSQL_SSL_KEY` | *unset* | TLS private key |
| `ICINGAWEB2_IDO_PGSQL_SSL_CERT` | *unset* | TLS public key |
| `ICINGAWEB2_IDO_PGSQL_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | CA |
| `ICINGAWEB2_IDO_PGSQL_CHARSET` | utf8 | Database charset for IDO |
| `ICINGAWEB2_PGSQL_HOST` | Sources `DEFAULT_PGSQL_HOST` | Icingaweb db host|
| `ICINGAWEB2_PGSQL_PORT` | Sources `DEFAULT_PGSQL_PORT` | Icingaweb db port |
| `ICINGAWEB2_PGSQL_USER` | Sources `DEFAULT_PGSQL_USER` | Icingaweb db user |
| `ICINGAWEB2_PGSQL_PASS` | Sources `DEFAULT_PGSQL_PASS` | Icingaweb db password |
| `ICINGAWEB2_PGSQL_DATA` | icingaweb2 | Icingaweb database name |
| `ICINGAWEB2_PGSQL_CHARSET` | utf8 | Icingaweb db charset |
| `ICINGAWEB2_PGSQL_SSL` | 0 | TLS |
| `ICINGAWEB2_PGSQL_SSL_KEY` | *unset* | TLS private key |
| `ICINGAWEB2_PGSQL_SSL_CERT` | *unset* | TLS public key |
| `ICINGAWEB2_PGSQL_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | CA |
| `ICINGAWEB2_DEPENDENCY` | false |  Enable module |
| `ICINGAWEB2_DEPENDENCY_PGSQL_HOST` | Sources `DEFAULT_PGSQL_HOST` | Db host |
| `ICINGAWEB2_DEPENDENCY_PGSQL_PORT` | Sources `DEFAULT_PGSQL_PORT` | Db port |
| `ICINGAWEB2_DEPENDENCY_PGSQL_USER` | Sources `DEFAULT_PGSQL_USER` | Db user |
| `ICINGAWEB2_DEPENDENCY_PGSQL_PASS` | sources `DEFAULT_PGSQL_PASS` | Db password |
| `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`| icinga2_dependencies | Db name |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | 0 | TLS |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | *unset* | TLS private key |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | *unset* | TLS public key |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | `/etc/ssl/certs/ca-certificates.crt` | CA |
| `ICINGAWEB2_DEPENDENCY_HOST` | Sources `ICINGAWEB2_API_TRANSPORT_HOST` | Icinga API host |
| `ICINGAWEB2_DEPENDENCY_PORT` | Sources `ICINGAWEB2_API_TRANSPORT_PORT` | Icinga API port |
| `ICINGAWEB2_DEPENDENCY_USER` | Source `DEFAULT_PGSQL_USER` | Icinga API user |
| `ICINGAWEB2_DEPENDENCY_PASS` | *random* | Icinga API password |
| `ICINGAWEB2_ADMIN_USER` | admin | Icingaweb admin |
| `ICINGAWEB2_ADMIN_PASS` | icinga | Icingaweb admin password |
| `ICINGAWEB2_FEATURE_GRAPHITE` | false | Enable Graphite |
| `ICINGAWEB2_FEATURE_GRAPHITE_URL` | http://${ICINGAWEB2_FEATURE_GRAPHITE_HOST} | Web-URL for Graphite |
| `ICINGAWEB2_FEATURE_DIRECTOR` | true | Enable Director |
| `ICINGAWEB2_FEATURE_DIRECTOR_KICKSTART` | true | Enable automatic Director Kickstart when necessary. Disabling this is not recommended |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_FQDN` | Sources `ICINGAWEB2_API_TRANSPORT_HOST` | Icinga monitoring endpoint domain name. Most of the time FQDN |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_HOST` | Sources `ICINGAWEB2_API_TRANSPORT_HOST` | Icinga API host |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_PORT` | Sources `ICINGAWEB2_API_TRANSPORT_PORT` | Icinga API port |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_USER` | Sources `ICINGAWEB2_API_TRANSPORT_USER` | Icinga API user |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_PASS` | Sources `ICINGAWEB2_API_TRANSPORT_PASS` | Icinga API user password |
| `ICINGAWEB2_DIRECTOR_PGSQL_HOST` | Sources `DEFAULT_PGSQL_HOST` | Director db host |
| `ICINGAWEB2_DIRECTOR_PGSQL_PORT` | Sources `DEFAULT_PGSQL_PORT` | Director db port |
| `ICINGAWEB2_DIRECTOR_PGSQL_USER` | Sources `DEFAULT_PGSQL_USER` | Director db user |
| `ICINGAWEB2_DIRECTOR_PGSQL_PASS` | Sources `DEFAULT_PGSQL_PASS` | Director db user password |
| `ICINGAWEB2_DIRECTOR_PGSQL_DATA` | icingaweb2_director | Director db name |
| `ICINGAWEB2_DIRECTOR_SSL` | 0 | TLS |
| `ICINGAWEB2_DIRECTOR_SSL_KEY` | *unset* | TLS private key |
| `ICINGAWEB2_DIRECTOR_SSL_CERT` | *unset* | TLS public key |
| `ICINGAWEB2_DIRECTOR_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | CA |
| `ICINGAWEB2_DIRECTOR_CHARSET` | utf8 | Director db charset |
| `ICINGAWEB2_GRAFANA` | false | Enable module |
| `ICINGAWEB2_GRAFANA_HOST` | grafana |  Grafana host |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARD` | *unset* | Default dashboard |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDUID` | *unset* | Dashboard ID |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDPANELID` | *unset* | Default pannel |
| `ICINGAWEB2_GRAFANA_PROXY_AUTHENTICATION` | token | Access type |
| `ICINGAWEB2_GRAFANA_PROXY_APITOKEN` | *unset* | API token |
| `ICINGAWEB2_GRAFANA_VERSION` | 1 | Version |
| `ICINGAWEB2_GRAFANA_PROTOCOL` | https | Protocol |
| `ICINGAWEB2_GRAFANA_SSLVERIFYPEER` | 0 | TLS verify peer |
| `ICINGAWEB2_GRAFANA_SSLVERIFYHOST` | 0 | TLS verify host |
| `ICINGAWEB2_GRAFANA_TIMERANGE` | 24h | Timerange |
| `ICINGAWEB2_GRAFANA_TIMERANGEALL` | 24h | Timerange for `Show All` |
| `ICINGAWEB2_GRAFANA_DEFAULTORGID` | 1 | Org ID |
| `ICINGAWEB2_GRAFANA_SHADOWS` | 1 | Graph shadows |
| `ICINGAWEB2_GRAFANA_THEME` | light | Grafana theme |
| `ICINGAWEB2_GRAFANA_DATASOURCE` | influxdb | Data source |
| `ICINGAWEB2_GRAFANA_ACCESSMODE` | indirectproxy | Grafana access |
| `ICINGAWEB2_GRAFANA_DIRECTREFRESH` | yes | Direct refresh |
| `ICINGAWEB2_GRAFANA_HEIGHT` | 280 | Hight |
| `ICINGAWEB2_GRAFANA_WIDTH` | 640 | Width |
| `ICINGAWEB2_GRAFANA_ENABLELINK` | yes | Link to Grafana |
| `ICINGAWEB2_GRAFANA_DEBUG` | 0 | Debugging |
| `ICINGAWEB2_GRAFANA_USEPUBLIC` | no | Public links |
| `ICINGAWEB2_MAP_DEFAULT_ZOOM` | 4 | Default zoom level |
| `ICINGAWEB2_MAP_DEFAULT_LAT`  | 52.515855 | Latitude |
| `ICINGAWEB2_MAP_DEFAULT_LON`  | 13.377485 | Longitude |
| `ICINGAWEB2_MAP_STATETYPE` | soft | Control state type |
| `ICINGAWEB2_MAP_MAX_ZOOM` | 19  | Maximum allowed zoom |
| `ICINGAWEB2_MAP_MAX_NATIVE_ZOOM` | 19 | Maximum  native zoom |
| `ICINGAWEB2_MAP_MIN_ZOOM` | 2 | Minimum zoom |
| `ICINGAWEB2_MAP_DASHLET_HEIGHT` | 300 | Dashlet size |
| `ICINGAWEB2_MAP_TITLE_URL` | -//{s}.tile.openstreetmap.org/{z}/{x}/{y}.png | Maps source URL |
| `ICINGAWEB2_MAP_CLUSTER_PROBLEM_COUNT` | 0 | Clouster problem count |
| `ICINGAWEB2_MAP_DISABLE_CLUSTER_AT_ZOOM` |18 | Hide cluster count at zoom level |
| `ICINGAWEB2_MAP_CONFIG_PATH` | /etc/icingaweb2/modules/map | Configuration directory |
| `ICINGAWEB2_MAP_CONFIG` | /config.ini | Config file |
| `APACHE2_HTTP` | `REDIRECT` | **Used only when both certificates are present**<br>`BOTH`: Allow HTTP and HTTPS connections<br>`REDIRECT`: Rewrite HTTP to HTTPS |
| `APACHE2_SERVER_NAME` | *icingaweb2* | Sets `ServerName`  |
| `APACHE2_SERVER_ALIAS` | *icingaweb* | Sets `ServerAlias` |
| `APACHE2_SERVER_ADMIN` | *webmaster@localhost* | Sets `ServerAdmin` |
| `APACHE2_CSP` | *unset* | Content security policy for Icingaweb |
| `APACHE2_OIDC_ENABLE` | false  | Enable module |
| `APACHE2_OIDC_METADATA_REFRESH` | 3600  | OIDC refresh interval |
| `APACHE2_OIDC_METADATA` | *unset* | Metadata URL |
| `APACHE2_OIDC_CLIENTID` | *unset* | Client ID |
| `APACHE2_OIDC_CLIENTSECRET` | *unset* | Client secret |
| `APACHE2_OIDC_SCOPE` | openid profile | OIDC scope |
| `APACHE2_OIDC_REDIRECT_URI` | /callback | Redirect URI |
| `APACHE2_OIDC_REMOTE_USER_CLAIM` | *unset* | User attribute map |
| `APACHE2_OIDC_PASSPHRASE` | *unset* | OIDC passphrase |
| `APACHE2_OIDC_SSL_VALIDATE_SERVER` | On | TLS validate server certificate |
| `APACHE2_OIDC_AUTHSSL_VALIDATE_SERVER` | On | TLS require valid certificate when communicating with authorization server (introspection endpoint) |
| `APACHE2_OIDC_INFOHOOK` | iat access_token access_token_expires id_token userinfo refresh_token session | Returened data when calling InfoHook |
| `APACHE2_OIDC_COOKIE_PATH` | / | Path for cookies `state` and `session` |
| `APACHE2_OIDC_REFRESH_TOKEN` | On | Use refresh tokens or not |
| `APACHE2_OIDC_SESSION_INACTIVITY_TIMEOUT` | 86400 | How before session is invalidated due to inactivity |
| `APACHE2_OIDC_SESSION_TYPE` | server-cache | Session type |
| `APACHE2_OIDC_SESSION_DURATION` | 86400 | Session duration |
| `APACHE2_OIDC_CACHE_ENCRYPT` | Off | OIDC encrypt cache |
| `APACHE2_OIDC_CACHE_TYPE` | file | OIDC Cache type (shm, memcache, file, redis) |
| `APACHE2_OIDC_CACHE_FALLBACK` | Off | Fallback to "OIDCSessionType client-cookie" when the primary cache mechanism (e.g. memcache or redis) fails |
| `APACHE2_OIDC_CACHE_DIR` | /var/cache/apache2/mod_auth_openidc/cache | Directory that holds cache files. Used when cache type is set to `file` |
| `APACHE2_OIDC_CACHE_FILE_CLEAN_INTERVAL` | *unset* | Cache file clean interval in seconds (only triggered on writes) for cache type `file` |
| `APACHE2_OIDC_CACHE_SHM_MAX` | *unset* | Specifies the maximum number of name/value pair entries that can be cached for cache type `shm` |
| `APACHE2_OIDC_CACHE_SHM_ENTRY_MAX` | *unset* | Specifies the maximum size for a single cache entry in bytes. Used with cache type `shm` |
| `APACHE2_OIDC_MEMCACHE_SERVERS` | *unset* | Specifies the memcache servers used for caching as a space separated list of <hostname>[:<port>] tuples |
| `APACHE2_OIDC_REDIS_SERVER` | *unset* | Specifies the Redis server used for caching as a <hostname>[:<port>] tuple |
| `APACHE2_OIDC_REDIS_PASSWORD` | *unset* | Password to be used if the Redis server requires [authentication](http://redis.io/commands/auth) |
| `APACHE2_OIDC_REDIS_DB` | *unset* | Logical database to [select](https://redis.io/commands/select) on the Redis server |
| `APACHE2_OIDC_REDIS_TIMEOUT` | *unset* | Timeout for connecting to the Redis servers |
| `APACHE2_OIDC_AUTH_REQUEST_PARAMS` | *unset* | Extra parameters will be sent along with the Authorization Request |
| `APACHE2_OIDC_XFORWARDED_HEADERS` | *unset* | Define the X-Forwarded-* or Forwarded headers that will be taken into account as set by a reverse proxy |
| `TZ` | UTC | Sets timezone for the container |
| `ICINGAWEB2_FEATURE_PHP_FPM` | true | Use PHP-FPM and mpm_event to process PHP |
| `PHP_FPM_OPCACHE_ENABLE` | 1 | Use FPM opcache |
| `PHP_FPM_OPCACHE_ENABLE_CLI` | 0 | Allow CLI for FPM opcache |
| `PHP_FPM_OPCACHE_FAST_SHUTDOWN` | 1 | Allow "fast_shutdown" for FPM opcache |
| `PHP_FPM_OPCACHE_MEMORY_CONSUMPTION` | 256M | Memory consumption for FPM opcache |
| `PHP_FPM_OPCACHE_STRINGS_BUFFER` | 16 | Strings buffer for FPM opcache |
| `PHP_FPM_OPCACHE_MAX_ACCELERATED` | 10000 | Accelerated file for FPM opcache |
| `PHP_FPM_OPCACHE_REVALIDATE_FREQ:-60` | 60 | Revalidate FPM opcache frequency |
| `PHP_FPM_MAX_POST` | 16M | Maximum POST size |
| `PHP_FPM_MAX_UPLOAD` | 16M | Maximum file size for upload |
| `PHP_FPM_MAX_EXECUTION_TIME` | 10800 | Maximum execution time |
| `PHP_FPM_MAX_INPUT_TIME` | 3600 | Maximum inout time |
| `PHP_FPM_EXPOSE` | Off | Show more PHP info to the world |
| `PHP_FPM_MEMORY_LIMIT` | 256M | Memory limit |
| `PHP_FPM_PM` | dynamic | Process spawning |
| `PHP_FPM_PM_SERVERS` | 10 | pm.start_servers |
| `PHP_FPM_PM_MIN` | 10 | pm.min_spare_servers |
| `TPHP_FPM_PM_MAX` | 32 | pm.max_spare_servers |
| `PHP_FPM_PM_IDLE` | 30 | Idle process limit |
| `PHP_FPM_PM_CHILDREN` | 48 | Maximum children |
| `PHP_FPM_PM_REQUESTS` | 0 | Maximum requests |
| `APACHE2_EVENT_SERVERS` | 3 | StartServers |
| `APACHE2_EVENT_MIN_SPARE` | 75 | MinSpareThreads |
| `APACHE2_EVENT_MAX_SPARE` | 250 | MaxSpareThreads |
| `APACHE2_EVENT_THREADS` | 64 | ThreadLimit |
| `APACHE2_EVENT_CHILD_THREADS` | 25 | ThreadsPerChild |
| `APACHE2_EVENT_WORKERS` | 400 | MaxRequestWorkers |
| `APACHE2_EVENT_CONN_PER_CHILD` | 0 | MaxConnectionsPerChild |
| `ICINGAWEB2_DOCKER_DEBUG` | 0 | Show detailed output of container scripts during start-up |


## Volumes

| Volume | ro/rw | Description & usage |
| ------ | ----- | ------------------- |
| /etc/apache2/ssl | **ro** | Mounted TLS certificates |
| /etc/locale.gen | **ro** | Using `locale.gen` file format. All localities included will be generated |
| /etc/icingaweb2 | rw | Icingaweb configuration directory |
| /var/lib/php/sessions/ | rw | Icingaweb PHP sessions |


# Credits

Created by Marek Jaroš at Institute of Computer Science of Masaryk Univerzity.

Very special thanks to the original author Jordan Jethwa.


# Licence

[GPL](LICENSE)
