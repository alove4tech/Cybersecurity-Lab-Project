# Mon01 Monitoring Server Deployment

## Overview

`mon01` is a Debian 12 Bookworm monitoring server deployed on the Cyberlab network. It consolidates Nagios Core, Grafana OSS, and Zabbix 7.0 LTS onto one host while keeping each web service on a separate port.

| Field | Value |
|---|---|
| Hostname | `mon01.corp.local` |
| IP address | `10.10.69.25/24` |
| Gateway | `10.10.69.1` |
| DNS server | `10.10.69.10` |
| DNS search domain | `corp.local` |
| OS | Debian 12 Bookworm minimal |
| Network | Cyberlab `10.10.69.0/24` |
| Deployment date | May 2026 |

## Service Port Map

| Service | Protocol / Port | Endpoint | Backend configuration |
|---|---|---|---|
| Apache2 / Nagios Core | TCP/80 | `http://10.10.69.25/nagios` | `/usr/local/nagios/etc/` |
| Grafana OSS | TCP/3000 | `http://10.10.69.25:3000` | `/etc/grafana/grafana.ini` |
| Nginx / Zabbix Frontend | TCP/8080 | `http://10.10.69.25:8080` | `/etc/zabbix/nginx.conf` |
| PostgreSQL | TCP/5432 | Local loopback `127.0.0.1` | `/etc/postgresql/15/main/` |

## Network and Identity Configuration

The VM was initially provisioned with DHCP, then converted to a static profile managed by `networking.service`.

Clear cached DHCP leases before applying the static profile:

```bash
sudo rm -f /var/lib/dhcp/dhclient.*
```

Set `/etc/network/interfaces` for the primary adapter:

```text
auto ens18
iface ens18 inet static
 address 10.10.69.25/24
 gateway 10.10.69.1
 dns-nameservers 10.10.69.10
 dns-search corp.local
```

Add local hostname mapping in `/etc/hosts`:

```text
10.10.69.25 mon01.corp.local mon01
```

Set the hostname:

```bash
sudo hostnamectl set-hostname mon01.corp.local
```

Align `/etc/resolv.conf` with the domain controller DNS service:

```text
domain corp.local
search corp.local
nameserver 10.10.69.10
```

## Package Repository Alignment

Debian minimal installs need extended package sections for some database, firmware, and web font dependencies. Enable `contrib`, `non-free`, and `non-free-firmware` in APT sources.

Example `/etc/apt/sources.list` entries:

```text
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
```

Refresh package metadata:

```bash
sudo apt clean
sudo apt update
```

## Grafana OSS

Install Grafana from the upstream APT repository:

```bash
sudo apt install -y apt-transport-https software-properties-common wget gpg
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install -y grafana
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server.service
```

Access Grafana at `http://10.10.69.25:3000`. Rotate the default `admin/admin` credentials immediately after first login.

## Zabbix 7.0 LTS

Install Zabbix server, frontend, agent, PostgreSQL, and required PHP driver packages:

```bash
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-1+debian12_all.deb
sudo dpkg -i zabbix-release_7.0-1+debian12_all.deb
sudo apt update
sudo apt install -y zabbix-server-pgsql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent php-pgsql postgresql postgresql-contrib
```

Provision the PostgreSQL database:

```bash
sudo -u postgres psql
```

```sql
CREATE USER zabbix WITH PASSWORD 'YourSecureLabPassword';
CREATE DATABASE zabbix OWNER zabbix;
\q
```

Import the base schema:

```bash
sudo zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
```

Set the database password in `/etc/zabbix/zabbix_server.conf`:

```text
DBPassword=YourSecureLabPassword
```

Configure `/etc/zabbix/nginx.conf` so Zabbix uses TCP/8080 and does not conflict with Apache on TCP/80:

```text
server {
 listen 8080;
 server_name mon01.corp.local;
```

Remove the default Nginx site and link the Zabbix site:

```bash
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/
```

Start and enable services:

```bash
sudo systemctl restart zabbix-server zabbix-agent nginx php8.2-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php8.2-fpm
```

Access Zabbix at `http://10.10.69.25:8080`. Rotate the default `Admin/zabbix` credentials immediately after first login. For the local PostgreSQL setup, leave database TLS unchecked during the web installer.

## Nagios Core

Nagios Core is compiled from source and served by Apache2 on TCP/80 under `/nagios`.

Install build dependencies and fetch source:

```bash
sudo apt install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php libgd-dev libssl-dev bc gawk dc build-essential snmp libnet-snmp-perl gettext
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.1.tar.gz
tar xzf nagios-4.5.1.tar.gz
cd nagios-4.5.1
```

Compile and install:

```bash
./configure --with-httpd-conf=/etc/apache2/sites-available
make all
sudo make install-groups-users
sudo usermod -a -G nagios www-data
sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config
sudo make install-webconf
```

Configure Apache integration and HTTP basic authentication:

```bash
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
sudo a2enmod cgi
sudo a2ensite nagios
sudo systemctl restart apache2
```

Compile and install Nagios plugins:

```bash
cd /tmp
wget https://nagios-plugins.org/download/nagios-plugins-2.4.8.tar.gz
tar xzf nagios-plugins-2.4.8.tar.gz
cd nagios-plugins-2.4.8
./configure
make
sudo make install
```

Enable Nagios:

```bash
sudo systemctl enable --now nagios
```

Access Nagios at `http://10.10.69.25/nagios` with the `nagiosadmin` HTTP basic-auth account.

## Cross-Integration

### Zabbix DC01 Host

Create a Zabbix host for the domain controller:

| Setting | Value |
|---|---|
| Location | Data collection -> Hosts -> Create host |
| Host name | `DC01` |
| Template | ICMP Ping |
| Interface | Agent, `10.10.69.10` |

### Grafana Zabbix Data Source

Install the Grafana Zabbix plugin:

```bash
cd /usr/share/grafana
sudo grafana cli plugins install alexanderzobnin-zabbix-app
sudo systemctl restart grafana-server
```

Add the Grafana data source:

| Setting | Value |
|---|---|
| Data source | Zabbix |
| API route | `http://10.10.69.25:8080/api_jsonrpc.php` |
| Authentication | Zabbix administrative web profile |

## Operational Notes

- Use a dedicated administrator workstation on `10.10.69.0/24` to access Grafana, Zabbix, and Nagios.
- Avoid browsing Grafana dashboards directly from DC01. Grafana dashboards rely on browser-side JavaScript and WebGL rendering, which can place unnecessary graphics and memory load on the domain controller desktop session.
- Keep DC01 focused on identity, DNS, and authentication services.
- Keep Zabbix, Grafana, and Nagios credentials separate and rotate all default credentials during initial setup.
