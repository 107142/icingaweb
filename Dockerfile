# Build on Debian 11
FROM --platform=${TARGETPLATFORM:-linux/amd64} debian:bullseye-slim

RUN printf "Running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a).\n"

# Basic info
ARG NAME
ARG BUILD_DATE
ARG VERSION=2.11.1
ARG VCS_REF
ARG VCS_URL

LABEL maintainer="Marek Jaroš <jaros@ics.muni.cz>" \
	org.label-schema.build-date=${BUILD_DATE} \
	org.label-schema.name=${NAME} \
	org.label-schema.description="Icingaweb2 interface" \
	org.label-schema.version=${VERSION} \
	org.label-schema.url="https://gitlab.ics.muni.cz/monitoring/icingaweb" \
	org.label-schema.vcs-ref=${VCS_REF} \
	org.label-schema.vcs-url=${VCS_URL} \
	org.label-schema.vendor="UVT-MUNI" \
	org.label-schema.schema-version="1.0"

ENV CODENAME=bullseye
ENV PACKAGE=2.11.1-1.${CODENAME}
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en
ARG OPENID_CONNECT=2.4.11.2

# Prepare environment
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get upgrade -y -f --no-install-recommends -o DPkg::options::="--force-unsafe-io" \
	&& apt-get install -y --no-install-recommends -o DPkg::options::="--force-unsafe-io" \
		ca-certificates \
		apt-transport-https \
		supervisor \
		apache2 \
		libapache2-mod-php \
		php-fpm \
		curl \
		dnsutils \
		file \
		gnupg \
		locales \
		netbase \
		openssl \
		php-curl \
		php-ldap \
		php-yaml \
		php-pgsql \
		php-mysql \
		php-mbstring \
		php-json \
		php-gmp \
		php-soap \
		php-intl \
		procps \
		unzip \
		wget \
		git \
		libnl-genl-3-200 \
		bc \
		xxd \
		brotli \
		ssl-cert \
		python3-openssl \
		python3-setuptools \
		python3-pip \
		python3-dev \
		python3-yaml \
		python3-urllib3 \
		libwww-perl \
		libjson-perl \
		libconfig-inifiles-perl \
		libnumber-format-perl \
		libdatetime-perl \
		iputils-ping \
		libhiredis0.14 \
		libcjose0 \
	# OpenID Connect
	&& ( wget -O /tmp/libapache2-mod-auth-openidc.deb https://github.com/zmartzone/mod_auth_openidc/releases/download/v$OPENID_CONNECT/libapache2-mod-auth-openidc_$OPENID_CONNECT-1.${CODENAME}+1_amd64.deb \
	&& dpkg -i /tmp/libapache2-mod-auth-openidc.deb; apt-get -f -y install ) \
	# Locales
	&& sed -i -E 's/^#?\ ?en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure locales

COPY content/ /

# Which module version to install
ARG GITREF_INCUBATOR=v0.17.0
ARG GITREF_DIRECTOR=v1.9.1
ARG GITREF_MODGRAPHITE=v1.2.1
ARG GITREF_MODAWS=v1.1.0
ARG GITREF_BUSSINESS=v2.4.0
ARG GITREF_GRAFANA=v1.4.2
ARG GITREF_PUPPETDB=master
# Master is required, see: https://github.com/visgence/icinga2-dependency-module/pull/9
ARG GITREF_DEPP=master
ARG GITREF_VSPHERE=v1.1.1
ARG GITREF_MAP=v1.1.0
ARG GITREF_GLOBE=v1.0.4

# Install Icingaweb
RUN export DEBIAN_FRONTEND=noninteractive \
	&& curl -s https://packages.icinga.com/icinga.key | gpg --dearmor > /usr/share/keyrings/icinga-keyring.gpg \
	&& curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /usr/share/keyrings/postgres-keyring.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/icinga-keyring.gpg] https://packages.icinga.com/debian icinga-$CODENAME main" > /etc/apt/sources.list.d/icinga2.list \
	&& echo "deb [signed-by=/usr/share/keyrings/postgres-keyring.gpg] https://apt.postgresql.org/pub/repos/apt/ $CODENAME-pgdg main" > /etc/apt/sources.list.d/$CODENAME-pgdg.list \
	&& apt-get update \
	&& apt-get -f -y install --no-install-recommends -o DPkg::options::="--force-unsafe-io" \
		icingacli=${PACKAGE} \
		icingaweb2=${PACKAGE} \
		icingaweb2-common=${PACKAGE} \
		icingaweb2-module-monitoring=${PACKAGE} \
		php-icinga=${PACKAGE} \
		icinga-php-library \
		icinga-php-thirdparty \
		postgresql-client

# Modules
RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
	# Icinga Director
	&& mkdir -p /usr/local/share/icingaweb2/modules/director/ \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/refs/tags/${GITREF_DIRECTOR}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
	# Icinga Incubator
	&& mkdir -p /usr/local/share/icingaweb2/modules/incubator/ \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-incubator/archive/refs/tags/${GITREF_INCUBATOR}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/incubator --exclude=.gitignore -f - \
	# Icingaweb2 Graphite
	&& mkdir -p /usr/local/share/icingaweb2/modules/graphite \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/refs/tags/${GITREF_MODGRAPHITE}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite --exclude=.gitignore -f - \
	# Icingaweb2 AWS
	&& mkdir -p /usr/local/share/icingaweb2/modules/aws \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/refs/tags/${GITREF_MODAWS}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws --exclude=.gitignore -f - \
	&& wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/2.8.30/aws.zip" \
	&& unzip -q -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
	&& rm aws.zip \
	# Icingaweb Bussinessprocess
	&& mkdir -p /usr/local/share/icingaweb2/modules/businessprocess \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-businessprocess/archive/refs/tags/${GITREF_BUSSINESS}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/businessprocess -f - \
	# Icingaweb Grafana
	&& mkdir -p /usr/local/share/icingaweb2/modules/grafana \
	&& wget -q --no-cookies -O - "https://github.com/Mikesch-mp/icingaweb2-module-grafana/archive/refs/tags/${GITREF_GRAFANA}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/grafana -f - \
	# Icingaweb Dependency module
	&& mkdir -p /usr/local/share/icingaweb2/modules/dependency_plugin \
	&& wget -q --no-cookies -O - "https://github.com/visgence/icinga2-dependency-module/archive/refs/heads/${GITREF_DEPP}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/dependency_plugin/ -f - \
	# Icingaweb PuppetDB module
	&& mkdir -p /usr/local/share/icingaweb2/modules/puppetdb \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-puppetdb/archive/refs/heads/${GITREF_PUPPETDB}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/puppetdb/ -f - \
	# Icingaweb vSphere module
	&& mkdir -p /usr/local/share/icingaweb2/modules/vsphere \
	&& wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-vsphere/archive/refs/tags/${GITREF_VSPHERE}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/vsphere/ -f - \
	# Icingaweb MAP module
	&& mkdir -p /usr/local/share/icingaweb2/modules/map \
	&& wget -q -O - "https://github.com/nbuchwitz/icingaweb2-module-map/archive/refs/tags/${GITREF_MAP}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/map/ -f - \
	# Icingaweb Globe module
	&& mkdir -p /usr/local/share/icingaweb2/modules/globe \
	&& wget -q -O - "https://github.com/Mikesch-mp/icingaweb2-module-globe/archive/refs/tags/${GITREF_GLOBE}.tar.gz" \
	| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/globe/ -f - \
	# Apache2 output
	&& sed -ri \
		-e 's!^(\s*CustomLog)\s+\S+!\1 /dev/stdout!g' \
		-e 's!^(\s*ErrorLog)\s+\S+!\1 /dev/stderr!g' \
		"/etc/apache2/apache2.conf" \
		"/etc/apache2/conf-available/other-vhosts-access-log.conf" \
	# FPM
	&& sed -ri \
		-e 's/error_log.*/error_log = \/dev\/stdout/g' \
		"/etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "\n";')/fpm/php-fpm.conf" \
	# Pre-compress static content
	&& find /usr/share/icingaweb2/public/ -type f -a \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.eot' -o -name '*.svg' -o -name '*.ttf' \) -exec brotli --best {} \+ \
	# Configuration touch-up
	&& mv -n /etc/icingaweb2/ /etc/icingaweb2.dist \
	&& chmod u+s,g+s \
		/bin/ping \
		/bin/ping6 \
	&& usermod -aG tty www-data \
	&& chmod o+w /dev/std* \
	&& mkdir -p /run/php/ /var/cache/apache2/mod_auth_openidc/cache/ && chown www-data /run/php /var/cache/apache2/mod_auth_openidc/cache \
	# Cleanup
	&& apt-get purge -y linux-libc-dev libc6-dev python-dev libc-dev-bin libexpat1-dev brotli \
	&& apt-get -f -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /var/lib/apt/lists/* /var/cache/ldconfig /var/cache/debconf /var/cache/apt

# Finalize
RUN chmod +x /opt/setup/* /opt/supervisor/* /opt/run /usr/local/bin/ini_set

ENV APACHE_RUN_USER=www-data APACHE_RUN_GROUP=www-data

EXPOSE 80 443

VOLUME [ "/etc/icingaweb2", "/var/lib/php/sessions" ]

HEALTHCHECK --interval=60s --timeout=10s --retries=2 --start-period=10s \
	CMD curl --fail http://127.0.0.1:80/icingaweb2/ || exit 1

ENTRYPOINT [ "/opt/run" ]

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n" ]
