#!/bin/bash

GREEN_COLOR='\033[0;32m'

echo -e "${GREEN_COLOR}Welcome To Installasi Manager LSP\n"

read -p "Masukan IP Linux (ex. 192.168.20.1): " ip_linux
read -p "Masukan IP Camera (ex. 192.168.20.1): " ip_camera
read -p "Masukan IP Briker (ex. 192.168.20.1): " ip_briker
read -p "Masukan NIS Kalian (ex. 13453): " nis


first_linux=$(echo $ip_linux | awk -F '.' '{print $4"."$3"."$2"."$1}'| cut  -d '.' -f 2-4)
rev_linux=$(echo $ip_linux | awk -F '.' '{print $4"."$3"."$2"."$1}'| cut  -d '.' -f 1)
rev_camera=$(echo $ip_camera | awk -F '.' '{print $4"."$3"."$2"."$1}'| cut  -d '.' -f 1)
rev_briker=$(echo $ip_briker | awk -F '.' '{print $4"."$3"."$2"."$1}'| cut  -d '.' -f 1)

read -p "Do you want to insert repository ? (y/n): " yn
ver_deb=$(cat  /etc/debian_version)
if [[ $ver_deb > "11" ]]
then
    case $yn in
        "y") echo "deb http://repo.antix.or.id/debian bullseye main contrib non-free
deb-src http://repo.antix.or.id/debian bullseye main contrib non-free
deb http://repo.antix.or.id/debian-security/ bullseye-security main contrib non-free
deb-src http://repo.antix.or.id/debian-security/ bullseye-security main contrib non-free
deb http://repo.antix.or.id/debian bullseye-updates main contrib non-free
deb-src http://repo.antix.or.id/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list && apt update -y
        ;;
        "n") echo "Okayy, next stepp, auto updating package"
        ;;
    esac
elif [[ $ver_deb < "11" ]]
then
    case $yn in
        "y") echo "deb http://kartolo.sby.datautama.net.id/debian/ buster main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian/ buster-updates main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ buster/updates main contrib non-free" >> /etc/apt/sources.list && apt update -y
        ;;
        "n") echo "Okayy, next stepp, auto updating package"
        ;;
    esac
fi

read -p "Do you want installation package for LSP ? (y/n): " yesno
case $yesno in
    "y") apt install apache2 wget unzip bind9 mariadb-server mariadb-client php7.3 apache2-utils libapache2-mod-php7.3 php7.3-cli php7.3-mysql -y
    ;;
    "n") 
        echo "Okayy thankyou..."
        exit 0
    ;;
esac

dns="smk$nis.co.id"

named_local="zone '$dns' {
    type master;
    file '/etc/bind/smk.int';
};
// Reverse-Lookup
zone '$first_linux.in-addr.arpa' {
    type master;
    file '/etc/bind/smk.rev';
};"

echo ";
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	$dns. root.$dns. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	        IN	NS	$dns.
$rev_linux	IN	PTR	$dns.
$rev_linux	IN	PTR	www.$dns.
$rev_linux	IN	PTR	cacti.$dns.
$rev_linux	IN	PTR	mail.$dns.
$rev_camera	IN	PTR	cctv.$dns.
$rev_briker	IN	PTR	voip.$dns."> /etc/bind/smk.rev

echo "; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	$dns. root.$dns. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	    IN	NS	$dns.
@	    IN	A	$ip_linux
cacti	IN	A	$ip_linux
mail   	IN	A	$ip_linux
www 	IN	A	$ip_linux
cctv	IN	A	$ip_camera
voip	IN	A	$ip_briker" > /etc/bind/smk.int

systemctl restart bind9
echo -e "${GREEN_COLOR} Success Setup DNS"

echo "<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	ServerName www.$dns
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/wordpress

	Include /phpmyadmin /var/www/pma/
	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	#Include conf-available/serve-cgi-bin.conf
</VirtualHost>" > /etc/apache2/sites-enabled/www.conf

wget https://wordpress.org/latest.zip && unzip latest.zip -d /var/www/

read -p "Masukan nama user untuk wordpress: " user_wordpress
read -p "Masukan nama database untuk wordpress: " user_db
read -p "Masukan password untuk wordpress: " user_pw

# Create Database For Wordpress
echo "create database $user_db;create user $user_wordpress identified by $user_pw;grant all privileges on $user_db.* to '$user_wordpress'@'localhost' identifed by '$user_pw';flush privileges; " | mysql -u root

# Configure wp_config.php
cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '${user_db}' );/" /var/www/wordpress/wp-config.php
sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '${user_wordpress}' );/" /var/www/wordpress/wp-config.php
sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '${user_pw}' );/" /var/www/wordpress/wp-config.php

systemctl restart apache2
echo -e "${GREEN_COLOR} Success Setup Wordpress"

# Configure Database for PMA
read -p "Masukan user untuk phpmyadmin: " user_pma
read -p "Masukan password untuk phpmyadmin: " pw_pma
read -p "Masukan database untuk phpmyadmin: " pma_db

echo "create database $pma_db;create user $user_pma identified by $pw_pma;grant all privileges on $pma_db.* to '$user_pma'@'localhost' identified by '$pw_pma';flush privileges;" | mysql -u root

# Configure file phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip
mv phpMyAdmin-5.2.0-all-languages.zip pma.zip
unzip pma.zip -d /var/www/ && mv /var/www/phpMyAdmin-5.2.0-all-languages /var/www/pma
mv /var/www/pma/config.sample.inc.php /var/www/pma/config.inc.php
sed -i "s/$cfg["blowfish_secret"] = '';/$cfg["blowfish_secret"] = "1";/" /var/www/pma/config.inc.php
sed -i "s/// $cfg['Servers'][$i]['controluser'] = 'pma';/$cfg['Servers'][$i]['controluser'] = '${user_pma}';/" /var/www/pma/config.inc.php
sed -i "s/// $cfg['Servers'][$i]['controlpass'] = 'pmapass';/$cfg['Servers'][$i]['controlpass'] = '${pw_pma}';/" /var/www/pma/config.inc.php
sed -i "s/// $cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';/$cfg['Servers'][$i]['pmadb'] = '${pma_db}';/" /var/www/pma/config.inc.php

systemctl restart apache2
echo -e "${GREEN_COLOR}Success Setup PhpMyAdmin"
