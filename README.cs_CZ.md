Tento repositář obsahuje zdroj pro [Docker](https://www.docker.com/) obraz řešení monitoringu [Icinga 2](https://www.icinga.org/).

**Obsahuje pouze kontejner pro Icingaweb. Jádro se nachází v samostatném [repozitáři](https://gitlab.ics.muni.cz/monitoring/icinga).**

**Pro produkci použijte tag `stable` nebo konkrétní [verzi](https://gitlab.ics.muni.cz/monitoring/icingaweb/container_registry/).**

**Můžete se také podívat na stránku [vydaných verzí](https://gitlab.ics.muni.cz/monitoring/icingaweb/-/releases).**

Docker image: [registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable](registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable)

[[_TOC_]]

# Icingaweb Docker

## Vlastnosti obrazu

1.  Postaven nad Debian Bullseye
2.  Klíčové vlastnosti:
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
    *  TLS podpora
    *  Podpora vlastních CA
    *  Podpora vlasních modulů
    *  Podpora vlastních skriptů
    *  Apache vHost
3.  Bez integrované databáze. Použijte officiální obraz k PostgreSQL
4.  Bez integrovaného Icinga monitorovacího jádra. Použijte separátní [obraz](https://gitlab.ics.muni.cz/monitoring/icinga)
5.  Bez SSH. Použijte `docker exec` nebo `nsenter`

## Stabilita

Tento projekt je primárně vyvíjen pro potřeby [Ústavu výpočení techniky](https://ics.muni.cz) Masarykovy univerzity. Je testován a beží v produkčním prostředí. Nicméně z důvodu limitovaných zdrojů nutných pro otestování každého modulu a funkce a prioritizace funkčností relevantních pro mě je možné že nějaké chyby jsou přitomny.

## Vývoj

Tento projekt je prozatím považován za funkčně kompletní a nebudu implementovat žádné nové funkce. Nicméně budu aktualizovat obraz a opravovat chyby pokud nastanou.

## Použití

Tento projekt předpokládá že máte pokročilé znalosti Dockeru, siťování, GNU/Linux a Icingy. Tato dokumentace rozhodně neslouží jako kompletní návod bod-po-bodu.

#### Rychlý start pomocí docker run

Nastartování nového kontejneru na portu 80 hosta. První příkaz vytvoří síť, druhý spustí kontejner s databází a třetí spustí kontejner se samotnou Icingou.  
```console
docker network create --ipv6 --driver=bridge --subnet=fd00:dead:beef::/48 icinet
docker run -d -e POSTGRES_PASSWORD=sec-pwd --net=icinet --name pgsql --hostname=pgsql postgres:13
docker run -d -p 5665:5665 --ulimit nofile=65536:65536 -e PGSQL_ROOT_PASS=sec-pwd -e DEFAULT_PGSQL_PASS=sec-pwd --net=icinet --name icinga2 --hostname=icinga2 registry.gitlab.ics.muni.cz:443/monitoring/icinga:stable
docker run -p 80:80 -e PGSQL_ROOT_PASS=sec-pwd -e DEFAULT_PGSQL_PASS=sec-pwd --net=icinet --name icingaweb2 --hostname=icingaweb2 -it registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```
Dosažitelné na http://localhost/icingaweb2/ s přihlašovacími údaji zobrazenými při startu kontejneru.

#### Docker-compose

Vzorová konfigurace pro [docker-compose](https://docs.docker.com/compose/) v `docker-compose.yml` souboru.  
Nastartuje Icinga(web)2 kontejnery s dalším PostgreSQL kontejnerem.  
```console
git clone git@gitlab.ics.muni.cz:/monitoring/icingaweb.git
docker-compose up
```
Dosažitelné na http://localhost/icingaweb2/ s přihlašovacími údaji zobrazenými při startu kontejneru.

#### Konfigurace

Konfigurace se nachází v `/etc/icinga2` a `/etc/icingaweb2`. Pro persistentní konfiguraci je dobré mít adresáře namontované jako svazky.

Pro IPv6 je možné použít Docker NAT s nastavením [ip6tables](https://docs.docker.com/engine/reference/commandline/dockerd/) nebo mít nadefinován správný subnet a použít [NDP](https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol).

#### Icinga připojení

Kontejner je potřeba připojit na monitorovací jádro Icingy. K tomu slouží API transport přes který se připojuje k jádru. Dále je třeba napojení k IDO databázi. Nastavujeme přes proměnné prostředí. Viz. sekce *Icingaweb 2* a seznam *proměnných na konci tohoto dokumentu*.


# Icingaweb

Icingaweb je přístupný na http://localhost/icingaweb2/ s přihlašovacími údaji *admin:icinga* (pokud nebyly nastaveny jinak přes proměnné prostředí).  
Icingaweb komunikuje s Icinga daemonem přes API transport s přihlašovacími údaji *icinga2-transport:icingatransport* (pokud nebyly nastaveny jinak přes proměnné prostředí).  
Při použití svazku `/etc/icingaweb2` je třeba nastastavit `ICINGAWEB2_ADMIN_USER` a `ICINGAWEB2_ADMIN_PASS`.

Proměnné pro API transport (výchozí hodnoty v závorce):

 * `ICINGAWEB2_API_TRANSPORT_HOST` Host kde běží daemon icinga2 (*icinga2*)
 * `ICINGAWEB2_API_TRANSPORT_PORT` Port API (*5665*)
 * `ICINGAWEB2_API_TRANSPORT_USER` Uživatel přístupu k API (*icinga2-transport*)
 * `ICINGAWEB2_API_TRANSPORT_PASS` Heslo k API (*icingatransport*)

## Apache2

Apache se nakonfiguruje automaticky. Pro produkci je ale dobré nastavit některé proměnné (kde to dává smysl):

 * `APACHE2_SERVER_NAME` nastaví *ServerName* direktivu - standardně bývá FQDN stroje na kterém webserver běží
 * `APACHE2_SERVER_ALIAS` nastaví  *ServerAlias*
 * `APACHE2_SERVER_ADMIN` nastavi *ServerAdmin*
 * `APACHE2_CSP` nastaví *Content-Security-Policy*hlavičky.

## Ukládání PHP relací

Pokud je třeba uložit PHP relace stačí namontovat svazek `/var/lib/php/sessions/` do kontejneru. Relační soubory budou uložneny v něm.

Příklad:  
```console
docker run [...] -v $PWD/icingaweb2-sessions:/var/lib/php/sessions/ registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```

## PHP-FPM

Ve výchozím stavu je PHP-FPM zapnuto včetně HTTP/2 protokolu. Stav kontroluje proměnná `ICINGAWEB2_FEATURE_PHP_FPM`.  
Proměnné prostředí kontrolující FPM se nachází v sekci [Reference](README.cs_CZ.md#reference).


# Grafana

Grafana není součástí kontejneru. Pro použití modulu je nutné mít připravenou instanci Grafany. Konfigurace (výchozí hodnoty v závorce):

 * `ICINGAWEB2_GRAFANA`: povolí použití modulu (`false`)
 * `ICINGAWEB2_GRAFANA_HOST`: adresa hosta s instancí Grafany (`grafana`)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARD`: výchozí dashboard (*nenastaveno*)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDUID`: ID dashboardu (*nenastaveno*)
 * `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDPANELID`: výchozí panel (*nenastaveno*)
 * `ICINGAWEB2_GRAFANA_PROXY_AUTHENTICATION`: forma přístupu (`token`)
 * `ICINGAWEB2_GRAFANA_PROXY_APITOKEN`: token pro API (*nenastaveno*)

Úplný seznam nastavení proměnných se nachází v sekci [Reference](README.cs_CZ.md#reference) na konci stránky.


# Graphite

Graphite není součástí kontejneru. Zapisovač může být zapnut nastavením proměnné `ICINGAWEB2_FEATURE_GRAPHITE` na hodnotu `true` nebo `1` a nastavením URL pro `ICINGAWEB2_FEATURE_GRAPHITE_URL`.

Příklad:
```console
docker run -t \
  --net=icinet  \
  -e ICINGAWEB2_FEATURE_GRAPHITE=true \
  -e ICINGAWEB2_FEATURE_GRAPHITE_URL=https://graphite.ics.muni.cz/ \
  registry.gitlab.ics.muni.cz:443/monitoring/icingaweb:stable
```


# Icinga Director

[Icinga Director](https://github.com/Icinga/icingaweb2-module-director)  modul je vy výchozím nastavení zapnut. Komunikuje s jádrem přes API transport. Nastavení přes proměnné prostředí - viz. seznam na konci.

Director se připojuje přes API a ještě přes Icinga endpoint, který je většinou specifikován jako FQDN. Aby Docker správně poslal síťový provoz na korektní kontejner je nutné vyhnout se několika stejným jménům hosta na jedno FQDN (parametr *--hostname*). Celé doménové jméno by mělo být tedy přiřazeno Icinga jádru, případně musí být použito více FQDN (pro Icinga a Icingaweb).

Je možné vypnout automatický kickstart při startu kontejneru nastavením proměnné `ICINGAWEB2_FEATURE_DIRECTOR_KICKSTART` na `false`.

Pro vypnutí directora stačí nastavit proměnnou `ICINGAWEB2_FEATURE_DIRECTOR` na `false`.


# Podpora TLS

Pro zapnutí TLS, namontujte adresář obsahující certifikáty na `/etc/apache2/ssl/icinga`. Jména certifikátů musí být:
 * `icinga2.chain`: Certifikační řetězec nebo samotný certifikát
 * `icinga2.key`: Korespondující privátní klíč

Pro Let's Encrypt certifikáty stačí namontovat adresář `/etc/letsencrypt` na `/etc/letsencrypt`. *Skript počítá pouze s jedním doménovým jménem v adresáři `live`.*  
Pro obnovu certifikátů CertBotem stačí namontovat webroot adresář na `/var/www` unitř kontejneru.

Pro HTTPS redirekci nebo HTTP/HTTPS dual-stack konsultujte `APACHE2_HTTP` proměnnou prostředí.


# Podpora vlastní CA

V případě potřeby použití vlastní či jiné certifikační authority, přidejte certifikáty jako `.crt` soubory do svazku namontovaném na `/usr/local/share/ca-certificates`.

Jakékoliv certifikační authority s příponou `.crt` v tomto svazku budou automaticky během startu přidány do CA úložiště.


# Vlastní moduly

K použití vlastních modulů je stačí nainstalovat do složky `enabledModules` ve svazku `/etc/icingaweb2`.


# Vlastní skript

Při spuštění kontejneru je možné spustit vlastní skript. Pro spustění stačí daný skript namontovat do souboru `/opt/custom_run`.
Skript bude spuštěn před startem ostatních komponent kontjeneru.


# Vlastní vHost

Pro přidání dalšího virtálního hosta do konfigurace Apache namontujtesoubor s konfigurací do `/etc/apache2/sites-available/custom_vhosts.conf` uvnitř kontejneru.

# Externí PostgreSQL databáze

Kontejner neobsahuje vlastní databázový server a vyžaduje použití vlastního kontejneru s databází nebo externí databázi.

Ke spojení kontejneru s externí databází se použijí proměnné prostředí. Pro každou databázi co Icinga používá se nachází sada proměnných nastavujícíh samotné spojení s ní. Teoreticky je možne databáze distrubuovat přes několik hostů.

Proměnné jsou kombinací služby a vlastnosí s formátem:
`<SERVICE>_PGSQL_<PROPERTY>`, kde
*  `<SERVICE>` může mít hodnoty: `ICINGAWEB2_IDO`, `ICINGAWEB2`, `ICINGAWEB2_DIRECTOR`, `ICINGAWEB2_DEPENDENCY`
*  `<PROPERTY>` může mít hodnoty: `HOST`, `PORT`, `DATA`, `USER`, `PASS`, `SSL`, `SSL_KEY`, `SSL_CERT`, `SSL_CA`, `CHARSET`

Proměnné využívají pro své výchozí hodnoty `DEFAULT` proměnnou:

*  `DEFAULT_PGSQL_HOST`: jméno hosta databázového serveru (default `pgsql`). Tato hodnota bude použita u služeb vyžadujících databázi, pokud nebude explicitně u specifické služby nastavena hodnota jiná.
*  `DEFAULT_PGSQL_PORT`: port serveru (default 5432)
*  `DEFAULT_PGSQL_DATA`: databáze (*nenastaveno*, specifické služby mají separátní databáze)
    *  `ICINGAWEB2_IDO_PGSQL_DATA`: databáze pro Icinga2-IDO (výhozí hodnota `icinga2_ido`)
    *  `ICINGAWEB2_PGSQL_DATA`:  databáze pro Icinga Web (výchozí hodnota `icingaweb2`)
    *  `ICINGAWEB2_DIRECTOR_PGSQL_DATA`: databáze pro Icinga Web Director (výchozí hodnota `icingaweb2_director`)
    *  `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`: databáze pro Icinga Web Depedency mapu (výchozí hodnota `icinga2_dependencies`)
*  `DEFAULT_PGSQL_USER`: uživatel pro k PostgreSQL databázi (ve výchozím nastavení `icinga2`)
*  `DEFAULT_PGSQL_PASS`: heslo pro PostgreSQL uživatele (ve výchozím nastavení *náhodně generované*)

## [PostreSQL TLS](https://www.postgresql.org/docs/13/libpq-ssl.html#LIBPQ-SSL-PROTECTION)

*TLS je výchozím nastavení vypnuto*. Pro připojení k databázím s certifikáty podepsanými známou certifikační authoritou stačí nastavit např. `ICINGAWEB2_PGSQL_SSL` na `1`. Pro vlastní CA nebo authentifikaci pomocí certifikátu je nutné tyto namontovat do kontejneru.

## Vytvoření databází a tabulek

Pro vytvoření relevantních databází, tabulek a schémat je třeba nastavit proměnné pro superuživatele PostgreSQL:

 * `PGSQL_ROOT_USER`: jméno superuživatele (default `postgres`)
 * `PGSQL_ROOT_PASS`: heslo superuživatele

Pokud nebude hodnota proměnné `PGSQL_ROOT_PASS` nastavena vytváření databází a tabulek bude přeskočeno. Je tedy možné po vytvoření všech databází tuto proměnnou nenastavovat. Databázi je také možné připravit [ručně](https://icinga.com/docs/icinga-2/latest/doc/02-installation/#setting-up-the-postgresql-database).


# Dependency module

Konfigurace přes proměnné. Ve výchozím stavu je modul vypnutý. Pro připojení je třeba přístup k API transportu. Proměnné (výchozí hodnota v závorkách):

 * `ICINGAWEB2_DEPENDENCY`: povolí použití modulu (`false`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_HOST`: adresa hosta pro databázi (`DEFAULT_PGSQL_HOST`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_PORT`: port serveru (`DEFAULT_PGSQL_PORT`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_USER`: uživatel databáze (`DEFAULT_PGSQL_USER`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_PASS`: heslo pro uživatele databáze (`DEFAULT_PGSQL_PASS`)
 * `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`: jméno databáze (`icinga2_dependencies`)
 * `ICINGAWEB2_DEPENDENCY_HOST`: Host icinga2 API (`ICINGAWEB2_API_TRANSPORT_HOST`)
 * `ICINGAWEB2_DEPENDENCY_PORT`: Port API (`ICINGAWEB2_API_TRANSPORT_PORT`)
 * `ICINGAWEB2_DEPENDENCY_USER`: jméno uživatele API (`ICINGAWEB2_API_TRANSPORT_USER`)
 * `ICINGAWEB2_DEPENDENCY_PASS`: heslo uživatele API (`ICINGAWEB2_API_TRANSPORT_PASS`)


# Business process

* `ICINGAWEB2_BUSSINESS`: povolí použití modulu (výchozí hodnota `true`)


# Map


* `ICINGAWEB2_MAP`: povolí použití modulu (výchozí hodnota `false`)

Úplný seznam nastavení proměnných se nachází v sekci [Reference](README.cs_CZ.md#reference) na konci stránky.


# OpenID Connect

Podpora pro OIDC je zapnuta přes proměnnou `APACHE2_OIDC_ENABLE`.

Pro úspěšnou funkci je třeba nastavit proměnné `APACHE2_OIDC_CLIENTID`, `APACHE2_OIDC_CLIENTSECRET`, `APACHE2_OIDC_REMOTE_USER_CLAIM` a cestu k metadatům poskytovatele `APACHE2_OIDC_METADATA`.

Icinga sama o sobě nijak s OIDC nespolupracuje, není tedy možné přejímat skupiny, atributy o uživatelých a další hodnoty. Funguje pouze jako SSO a předává uživatele přes `REMOTE_USER` hlavičku s tím že ostatní je třeba vyřešit pres LDAP nebo lokální skupiny v databázi.


# Logování

Směrování logů lze nastavit přes [ovladače Dockeru](https://docs.docker.com/config/containers/logging/configure/).

Vypsat logy lze v defaultní konfiguraci například příkazem `docker logs icingaweb`.


# Reference

## Seznam proměnných prostředí

| Proměnná prostředí | Výchozí hodnota | Popis |
| ---------------------- | ------------- | ----------- |
| `ICINGAWEB2_API_TRANSPORT_HOST` | icinga2 | Host na kterém beží daemon icinga2 s povoleným API. |
| `ICINGAWEB2_API_TRANSPORT_PORT` | 5665 | Port API |
| `ICINGAWEB2_API_TRANSPORT_USER` | icinga2-transport | Uživatel pro API transport. |
| `ICINGAWEB2_API_TRANSPORT_PASS` | icingatransport | Heslo pro API transport. |
| `PGSQL_ROOT_USER` | postgres | Jméno superuživatele databáze |
| `PGSQL_ROOT_PASS` | *nenastaveno* | Heslo pro superuživatel databáze aby mohla Icinga vytvořit nezbytné tabulky a schémata. Jeho absence předpokládá že databáze jsou již nastaveny. | |
| `DEFAULT_PGSQL_USER` | icinga2 | Uživatel pro k PostgreSQL databázi |
| `DEFAULT_PGSQL_PASS` | *náhodně generované* | Heslo pro PostgreSQL uživatele |
| `DEFAULT_PGSQL_HOST` | pgsql | Jméno hosta databázového serveru. Tato hodnota bude použita u služeb vyžadujících databázi, pokud nebude explicitně u specifické služby nastavena hodnota jiná. |
| `DEFAULT_PGSQL_PORT` | 5432 | Port serveru |
| `DEFAULT_PGSQL_DATA` | *nenastaveno* | Databáze (specifické služby mají separátní databáze) |
| `ICINGAWEB2_LOGGING_LEVEL` | ERROR | Úroveň logování pro Icingaweb |
| `ICINGAWEB2_IDO_PGSQL_HOST` | Zdrojuje `DEFAULT_PGSQL_HOST` | PostgreSQL host kde beží databáze pro IDO |
| `ICINGAWEB2_IDO_PGSQL_PORT` | Zdrojuje `DEFAULT_PGSQL_PORT` | PostgreSQL port |
| `ICINGAWEB2_IDO_PGSQL_USER` | Zdrojuje `DEFAULT_PGSQL_USER` | Uživatel pro připojení k IDO |
| `ICINGAWEB2_IDO_PGSQL_PASS` | Zdrojuje `DEFAULT_PGSQL_PASS` | Heslo uživatele pro připojení k IDO |
| `ICINGAWEB2_IDO_PGSQL_DATA` | icinga2_ido | Databáze pro Icinga2-IDO |
| `ICINGAWEB2_IDO_PGSQL_SSL` | 0 | Zapne TLS pro komunikaci s databází. |
| `ICINGAWEB2_IDO_PGSQL_SSL_KEY` | *nenastaveno* | TLS privátní klíč |
| `ICINGAWEB2_IDO_PGSQL_SSL_CERT` | *nenastaveno* | TLS veřejný klíč |
| `ICINGAWEB2_IDO_PGSQL_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | Certifikační authorita |
| `ICINGAWEB2_IDO_PGSQL_CHARSET` | utf8 | Charset pro databázi |
| `ICINGAWEB2_PGSQL_HOST` | Zdrojuje `DEFAULT_PGSQL_HOST` | PostgreSQL host kde beží databáze pro web|
| `ICINGAWEB2_PGSQL_PORT` | Zdrojuje `DEFAULT_PGSQL_PORT` | PostgreSQL port |
| `ICINGAWEB2_PGSQL_USER` | Zdrojuje `DEFAULT_PGSQL_USER` | Uživatel pro připojení datbáze pro web |
| `ICINGAWEB2_PGSQL_PASS` | Zdrojuje `DEFAULT_PGSQL_PASS` | Heslo uživatele pro připojení databáze pro web |
| `ICINGAWEB2_PGSQL_DATA` | icingaweb2 | Databáze pro Icinga Web |
| `ICINGAWEB2_PGSQL_CHARSET` | utf8 | Charset pro databázi. |
| `ICINGAWEB2_PGSQL_SSL` | 0 | Zapne TLS pro komunikaci s databází |
| `ICINGAWEB2_PGSQL_SSL_KEY` | *nenastaveno* | TLS privátní klíč |
| `ICINGAWEB2_PGSQL_SSL_CERT` | *nenastaveno* | TLS veřejný klíč |
| `ICINGAWEB2_PGSQL_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | Certifikační authorita |
| `ICINGAWEB2_DEPENDENCY` | false |  Povolí použití modulu |
| `ICINGAWEB2_DEPENDENCY_PGSQL_HOST` | Zdrojuje `DEFAULT_PGSQL_HOST` | Adresa hosta pro databázi  |
| `ICINGAWEB2_DEPENDENCY_PGSQL_PORT` | Zdrojuje `DEFAULT_PGSQL_PORT` | Port serveru |
| `ICINGAWEB2_DEPENDENCY_PGSQL_USER` | Zdrojuje `DEFAULT_PGSQL_USER` | Uživatel databáze |
| `ICINGAWEB2_DEPENDENCY_PGSQL_PASS` | Zdrojuje `DEFAULT_PGSQL_PASS` | Heslo pro uživatele databáze |
| `ICINGAWEB2_DEPENDENCY_PGSQL_DATA`| icinga2_dependencies | Jméno databáze pro Icinga Web Depedency mapu |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | 0 | Zapne TLS pro komunikaci s databází |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | *nenastaveno* | TLS privátní klíč |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | *nenastaveno* | TLS veřejný klíč |
| `ICINGAWEB2_DEPENDENCY_PGSQL_SSL` | `/etc/ssl/certs/ca-certificates.crt` | Certifikační authorita |
| `ICINGAWEB2_DEPENDENCY_HOST` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_HOST` | Icinga API host |
| `ICINGAWEB2_DEPENDENCY_PORT` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_PORT` | Icinga API port |
| `ICINGAWEB2_DEPENDENCY_USER` | icinga2 | Icinga API uživatel |
| `ICINGAWEB2_DEPENDENCY_PASS` |*náhodně generované* | Icinga API heslo |
| `ICINGAWEB2_ADMIN_USER` | admin | Jméno administrátora pro Icinga Web |
| `ICINGAWEB2_ADMIN_PASS` | icinga | Heslo administrátora proc Icinga Web |
| `ICINGAWEB2_FEATURE_GRAPHITE` | false | Nastav na `true` nebo `1` pro zapnutí graphite zapisovače |
| `ICINGAWEB2_FEATURE_GRAPHITE_URL` | http://${ICINGAWEB2_FEATURE_GRAPHITE_HOST} | Web-URL pro Graphite |
| `ICINGAWEB2_FEATURE_DIRECTOR` | true | Nastav na `false` nebo `0` pro vypnutí directora |
| `ICINGAWEB2_FEATURE_DIRECTOR_KICKSTART` | true | Nastav `false` pro vypnutí automatického kickstartu directora při startu kontejneru. *Hodnota má význam pouze pokud je director zapnutý* |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_FQDN` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_HOST` | Doménové jméno endpointu na kterém beží Icinga2. Většinou FQDN. |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_HOST` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_HOST` | Adresa hosta |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_PORT` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_PORT` | Port API |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_USER` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_USER` | Uživatel pro API transport directora |
| `ICINGAWEB2_DIRECTOR_ENDPOINT_PASS` | Zdrojuje `ICINGAWEB2_API_TRANSPORT_PASS` | Heslo uživatele API transportu directora |
| `ICINGAWEB2_DIRECTOR_PGSQL_HOST` | Zdrojuje `DEFAULT_PGSQL_HOST` | Adresa databáze pro directora |
| `ICINGAWEB2_DIRECTOR_PGSQL_PORT` | Zdrojuje `DEFAULT_PGSQL_PORT` | Port databáze |
| `ICINGAWEB2_DIRECTOR_PGSQL_USER` | Zdrojuje `DEFAULT_PGSQL_USER` | Uživatel databáze |
| `ICINGAWEB2_DIRECTOR_PGSQL_PASS` | Zdrojuje `DEFAULT_PGSQL_PASS` | Heslo databáze |
| `ICINGAWEB2_DIRECTOR_PGSQL_DATA` | icingaweb2_director | Databáze pro Icinga Web Director |
| `ICINGAWEB2_DIRECTOR_SSL` | 0 | Zapne TLS pro komunikaci s databází. |
| `ICINGAWEB2_DIRECTOR_SSL_KEY` | *nenastaveno* | TLS privántí klíč |
| `ICINGAWEB2_DIRECTOR_SSL_CERT` | *nenastaveno* | TLS veřejný klíč |
| `ICINGAWEB2_DIRECTOR_SSL_CA` | `/etc/ssl/certs/ca-certificates.crt` | Certifikační authorita |
| `ICINGAWEB2_DIRECTOR_CHARSET` | utf8 | Charset pro databázi. |
| `ICINGAWEB2_GRAFANA` | false | Povolí použití modulu |
| `ICINGAWEB2_GRAFANA_HOST` | grafana |  Adresa hosta s instancí Grafany |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARD` | *nenastaveno* | Výchozí dashboard |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDUID` | *nenastaveno* | ID dashboardu |
| `ICINGAWEB2_GRAFANA_DEFAULTDASHBOARDPANELID` | *nenastaveno* | Výchozí panel |
| `ICINGAWEB2_GRAFANA_PROXY_AUTHENTICATION` | token | Forma přístupu |
| `ICINGAWEB2_GRAFANA_PROXY_APITOKEN` | *nenastaveno* | Token pro API |
| `ICINGAWEB2_GRAFANA_VERSION` | 1 | Verze |
| `ICINGAWEB2_GRAFANA_PROTOCOL` | https | Protocol |
| `ICINGAWEB2_GRAFANA_SSLVERIFYPEER` | 0 | Kontrola klienta |
| `ICINGAWEB2_GRAFANA_SSLVERIFYHOST` | 0 | Kontrola hosta |
| `ICINGAWEB2_GRAFANA_TIMERANGE` | 24h | Časové rozpětí |
| `ICINGAWEB2_GRAFANA_TIMERANGEALL` | 24h | Časovové rozpětí pro `Show All` |
| `ICINGAWEB2_GRAFANA_DEFAULTORGID` | 1 | ID organizace |
| `ICINGAWEB2_GRAFANA_SHADOWS` | 1 | Stíny grafu |
| `ICINGAWEB2_GRAFANA_THEME` | light | Théma grafu |
| `ICINGAWEB2_GRAFANA_DATASOURCE` | influxdb | Zdroj dat |
| `ICINGAWEB2_GRAFANA_ACCESSMODE` | indirectproxy | Přístup ke grafům |
| `ICINGAWEB2_GRAFANA_DIRECTREFRESH` | yes | Přímá obnova |
| `ICINGAWEB2_GRAFANA_HEIGHT` | 280 | Výška grafu |
| `ICINGAWEB2_GRAFANA_WIDTH` | 640 | Šířka grafu |
| `ICINGAWEB2_GRAFANA_ENABLELINK` | yes | Odkaz do Grafany |
| `ICINGAWEB2_GRAFANA_DEBUG` | 0 | Zapni debugging |
| `ICINGAWEB2_GRAFANA_USEPUBLIC` | no | Veřejné odkazy |
| `ICINGAWEB2_MAP_DEFAULT_ZOOM` | 4 | Výchozí úroveň přiblížení mapy |
| `ICINGAWEB2_MAP_DEFAULT_LAT`  | 52.515855 | Zeměpisná šířka |
| `ICINGAWEB2_MAP_DEFAULT_LON`  | 13.377485 | Zeměpisná délka |
| `ICINGAWEB2_MAP_STATETYPE` | soft | Stav kontrol |
| `ICINGAWEB2_MAP_MAX_ZOOM` | 19  | Maximální přiblížení |
| `ICINGAWEB2_MAP_MAX_NATIVE_ZOOM` | 19 | Maximální nativní přiblížení |
| `ICINGAWEB2_MAP_MIN_ZOOM` | 2 | minální přiblížení |
| `ICINGAWEB2_MAP_DASHLET_HEIGHT` | 300 | Velikost dashletu |
| `ICINGAWEB2_MAP_TITLE_URL` | -//{s}.tile.openstreetmap.org/{z}/{x}/{y}.png | URL pro mapy |
| `ICINGAWEB2_MAP_CLUSTER_PROBLEM_COUNT` | 0 | Počet probém clusteru |
| `ICINGAWEB2_MAP_DISABLE_CLUSTER_AT_ZOOM` |18 | Vypni zobrazení počtu pblémů clusteru u přiblížení |
| `ICINGAWEB2_MAP_CONFIG_PATH` | /etc/icingaweb2/modules/map | Cesta konfigurace |
| `ICINGAWEB2_MAP_CONFIG` | /config.ini | konfigurační soubor |
| `APACHE2_HTTP` | `REDIRECT` | **Proměnná je aktivní pouze pokud oba certifikáty jsou přitomny.** `BOTH`: Povol HTTP a HTTPS spojení. `REDIRECT`: Přepiš HTTP-požadavky na HTTPS |
| `APACHE2_SERVER_NAME` | *icingaweb2* | Globálně nastaví `ServerName` pro Apache2 na danou hodnotu |
| `APACHE2_SERVER_ALIAS` | *icingaweb* | Globálně nastaví `ServerAlias` pro Apache2 na danou hodnotu |
| `APACHE2_SERVER_ADMIN` | *webmaster@localhost* | Globálně nastaví `ServerAdmin` pro Apache2 na danou hodnotu |
| `APACHE2_CSP` | *nenastaveno* | Content security policy pro Icingaweb. |
| `APACHE2_OIDC_ENABLE` | false  | Zapni podporu SSO přes OpenID Connect |
| `APACHE2_OIDC_METADATA_REFRESH` | 3600  | Interval obnovy metadat pro OIDC |
| `APACHE2_OIDC_METADATA` | *nenastaveno* | URL k metadatům poskytovatele |
| `APACHE2_OIDC_CLIENTID` | *nenastaveno* | ID klienta |
| `APACHE2_OIDC_CLIENTSECRET` | *nenastaveno* | Tajemství klienta |
| `APACHE2_OIDC_SCOPE` | openid profile | Požadavky k OIDC |
| `APACHE2_OIDC_REDIRECT_URI` | /callback | Presměrující URI |
| `APACHE2_OIDC_REMOTE_USER_CLAIM` | *nenastaveno* | Na který atribut namapovat uživatelské jméno |
| `APACHE2_OIDC_PASSPHRASE` | *nenastaveno* | OIDC heslo |
| `APACHE2_OIDC_SSL_VALIDATE_SERVER` | On | Požaduj validní certifikát při komunikaci s OIDC poskytovatelem |
| `APACHE2_OIDC_AUTHSSL_VALIDATE_SERVER` | On | Požaduj validní certifikát při komunikaci s authorizačním serverem (introspection endpoint) |
| `APACHE2_OIDC_INFOHOOK` | iat access_token access_token_expires id_token userinfo refresh_token session | Vrácená data při volání InfoHook |
| `APACHE2_OIDC_COOKIE_PATH` | / | Cesta  pro koláčky typu `state` a `session` |
| `APACHE2_OIDC_REFRESH_TOKEN` | On | Určuje zda předat obnovovací příznak aplikaci |
| `APACHE2_OIDC_SESSION_INACTIVITY_TIMEOUT` | 86400 | Interval v sekundách po kterém bude relace zneplatněna, pokud nedojde k žádné interakci |
| `APACHE2_OIDC_SESSION_TYPE` | server-cache | Typ ukládání relace |
| `APACHE2_OIDC_SESSION_DURATION` | 86400 | Maximální délka aplikační relace v sekundách |
| `APACHE2_OIDC_CACHE_ENCRYPT` | Off | Zapíná šifrování mezipaměti serveru |
| `APACHE2_OIDC_AUTH_REQUEST_PARAMS` | *nenastaveno* | Další parametry budou poslány společně s autorizačním požadavkem |
| `TZ` | UTC | Nastav časové pásmo které má kontejner použít |
| `ICINGAWEB2_FEATURE_PHP_FPM` | true | Použij PHP-FPM a mpm_event ke zpracování PHP |
| `PHP_FPM_OPCACHE_ENABLE` | 1 | Použij FPM opcache |
| `PHP_FPM_OPCACHE_ENABLE_CLI` | 0 | Povol CLI pro FPM opcache |
| `PHP_FPM_OPCACHE_FAST_SHUTDOWN` | 1 | Povol "fast_shutdown" pro FPM opcache |
| `PHP_FPM_OPCACHE_MEMORY_CONSUMPTION` | 256M | Spotřeba paměti pro FPM opcache |
| `PHP_FPM_OPCACHE_STRINGS_BUFFER` | 16 | Mezipamět pro řtězce FPM opcache |
| `PHP_FPM_OPCACHE_MAX_ACCELERATED` | 10000 | Množství urychlených souborů pro FPM opcache |
| `PHP_FPM_OPCACHE_REVALIDATE_FREQ:-60` | 60 | Frekvence revalidace FPM opcache |
| `PHP_FPM_MAX_POST` | 16M | Maximální velikost POST |
| `PHP_FPM_MAX_UPLOAD` | 16M | Maximální veikost pro nahrání souboru |
| `PHP_FPM_MAX_EXECUTION_TIME` | 10800 | Maximální délka trvání činnosti FPM |
| `PHP_FPM_MAX_INPUT_TIME` | 3600 | Maximání čas pro vstup |
| `PHP_FPM_EXPOSE` | Off | Zobraz další informace o PHP verzi světu |
| `PHP_FPM_MEMORY_LIMIT` | 256M | Limit paměti pro FPM |
| `PHP_FPM_PM` | dynamic | Typ vytváření nových procesů FPM |
| `PHP_FPM_PM_SERVERS` | 10 | pm.start_servers |
| `PHP_FPM_PM_MIN` | 10 | pm.min_spare_servers |
| `TPHP_FPM_PM_MAX` | 32 | pm.max_spare_servers |
| `PHP_FPM_PM_IDLE` | 30 | Limit pro nečinnost procesu |
| `PHP_FPM_PM_CHILDREN` | 48 | Maximální počet dětí FPM |
| `PHP_FPM_PM_REQUESTS` | 0 | Maximum požadavků na proces před jeho restartem |
| `APACHE2_EVENT_SERVERS` | 3 | StartServers |
| `APACHE2_EVENT_MIN_SPARE` | 75 | MinSpareThreads |
| `APACHE2_EVENT_MAX_SPARE` | 250 | MaxSpareThreads |
| `APACHE2_EVENT_THREADS` | 64 | ThreadLimit |
| `APACHE2_EVENT_CHILD_THREADS` | 25 | ThreadsPerChild |
| `APACHE2_EVENT_WORKERS` | 400 | MaxRequestWorkers |
| `APACHE2_EVENT_CONN_PER_CHILD` | 0 | MaxConnectionsPerChild |
| `ICINGAWEB2_DOCKER_DEBUG` | 0 | Detailní výstup startovních skripů kontejneru |


## Reference ke svazkům

| Svazek | ro/rw | Popis & použití |
| ------ | ----- | ------------------- |
| /etc/apache2/ssl | **ro** | Namontování TLS certifikátů (viz. Podpora TLS) |
| /etc/locale.gen | **ro** | Ve formátu `locale.gen` souboru. Všechny lokality v tomto souboru budou generovány. |
| /etc/icingaweb2 | rw | Icingaweb2 adresář s konfigurací |
| /var/lib/php/sessions/ | rw | Icingaweb2 PHP relační soubory |

# Credits

Vytvořil Marek Jaroš pro Ústav výpočetní techniky Masarykovy univerzity.

Velmi speciální poděkování původnímu autorovi Jordanovi Jethwa.

# Licence

[GPL](LICENSE)
