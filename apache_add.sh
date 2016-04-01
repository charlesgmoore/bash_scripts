#!/bin/bash
echo  './addit.sh [domain.com] [clientusername] [SSL-IP]'
read -p "check syntax matches <enter>"

if [ -d /etc/httpd/conf.d ]; then
  CONF=/etc/httpd/conf.d/$1.conf
else
  CONF=/etc/apache2/conf.d/$1.conf
fi
HOSTNAME="$(hostname -f)"
if [ -z $1 ]; then
  echo "You did not specify a domain."
  echo "Usage: ./addit.sh [domain.com] [clientusername] [SSL-IP]"
  exit 1
fi

if [[ "$1" =~ "www." ]]; then
  echo "Do not put www in front of the domain."
  exit 1
fi

if [ -z $2 ]; then
  echo "You did not specify what user will own the files."
  exit 1
fi

if [ -e $CONF ]; then
  read -p "$CONF already exists!  Last chance before I overwrite $CONF <enter>"
  /bin/echo -n > $CONF
fi

echo "Creating apache config $1.conf and dirs"

if [ ! -d /var/www/$1/htdocs ];then
  mkdir -p /var/www/$1/htdocs
  chown -R $2.apache /var/www/$1/htdocs
  chmod g+s /var/www/$1/htdocs
else
  echo "directories already exist - creating config only"
  read -p "<enter>"
fi

# Not necessary; cronolog does this for us.
#if [ ! -d /var/www/$1/logs ]; then
#  mkdir -p /var/www/$1/logs
#fi

echo "<VirtualHost *:80>" >> $CONF
echo "		ServerName $1" >> $CONF
echo "		ServerAlias www.$1" >> $CONF
echo "		ServerAlias $1.$HOSTNAME" >> $CONF
echo "		DocumentRoot /var/www/$1/htdocs" >> $CONF
echo "		<Directory /var/www/$1/htdocs>" >> $CONF
echo "		Options All" >> $CONF
echo "		Allow from all" >> $CONF
echo "		AllowOverride All" >> $CONF
echo "		</Directory>" >> $CONF
echo "		ErrorLog \"|/usr/sbin/cronolog /var/www/$1/logs/%Y/%m/%Y%m%d-error.log\"" >> $CONF
echo "		CustomLog \"|/usr/sbin/cronolog /var/www/$1/logs/%Y/%m/%Y%m%d-access.log\" combined" >> $CONF
echo "</VirtualHost>" >> $CONF
echo "" >> $CONF

if [ -z "$3" ]; then
  COMMENT='#'
else
  COMMENT=''
  mkdir -p /var/www/$1/certs
fi
echo "$COMMENT<VirtualHost $3:443>" >> $CONF
echo "$COMMENT		ServerName $1" >> $CONF
echo "$COMMENT		ServerAlias www.$1" >> $CONF
echo "$COMMENT		ServerAlias $1.$HOSTNAME" >> $CONF
echo "$COMMENT		DocumentRoot /var/www/$1/htdocs" >> $CONF
echo "$COMMENT		ErrorLog \"|/usr/sbin/cronolog /var/www/$1/logs/%Y/%m/%Y%m%d-ssl-error.log\"" >> $CONF
echo "$COMMENT		CustomLog \"|/usr/sbin/cronolog /var/www/$1/logs/%Y/%m/%Y%m%d-ssl-access.log\" combined" >> $CONF
echo "$COMMENT		<Directory /var/www/$1/htdocs>" >> $CONF
echo "$COMMENT		Options All" >> $CONF
echo "$COMMENT		Allow from all" >> $CONF
echo "$COMMENT		AllowOverride All" >> $CONF
echo "$COMMENT		</Directory>" >> $CONF
echo "$COMMENT		SSLEngine On" >> $CONF
echo "$COMMENT		SSLCertificateFile /var/www/$1/certs/$1.crt" >> $CONF
echo "$COMMENT		SSLCertificateKeyFile /var/www/$1/certs/$1.key" >> $CONF
echo "$COMMENT		SSLCertificateChainFile /var/www/$1/certs/intermediate.crt" >> $CONF
echo "$COMMENT		SSLCipherSuite \"ALL:!aNULL:!ADH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH:+MEDIUM\"" >> $CONF
echo "$COMMENT</VirtualHost>" >> $CONF