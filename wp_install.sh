#!/bin/bash

#This script will "do the needful" to install wordpress then output the information. 
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"
MY_DOCROOT=""
MY_DB_USER=""
MY_DB_NAME=""
MY_DB_PASS=""
MY_GRANT_IP=""
MY_DB_ANSWER=''
MY_ANSWER=""
MY_SITE_URL=""
MY_WP_URL=http://wordpress.org/latest.tar.gz
MY_WP_SALT="$(perl -npe "s/[^A-Za-z0-9]//g;" /dev/urandom | head -c 15)"
MY_HOSTS_IP="$(curl -s ifconfig.me)"
MY_WP_PASS="$(perl -npe "s/[^A-Za-z0-9]//g;" /dev/urandom | head -c 10)"
MY_DB_PASS="$(perl -npe "s/[^A-Za-z0-9]//g;" /dev/urandom | head -c 10)"

#Gather Info
read -p "Site name: " MY_SITE_URL
read -p "Path to docroot including training slash: " MY_DOCROOT
read -p "Database name: " MY_DB_NAME
read -p "Database user: " MY_DB_USER
read -e -p  "Database pass: " -i " $MY_DB_PASS" MY_DB_PASS
while true; do
read -e -p 'Is MySQL local to the box? y/n ' -i " y" MY_DB_ANSWER
    case $MY_DB_ANSWER in
        [Yy]* ) MY_GRANT_IP='localhost'; break;;
        [Nn]* ) MY_GRANT_IP="$MY_HOSTS_IP"; break;;
        * ) echo 'Please choose y/n. ';;
    esac
done
while true; do
read -e -p 'Are you sure all the information is correct? y/n ' -i " y" MY_ANSWER
    case $MY_ANSWER in
        [Yy]* ) echo 'Installing...'; break;;
        [Nn]* ) echo 'Exiting...'; exit 1;;
        * ) echo 'Please choose y/n. ';;
    esac
done
echo -e ''

#Checks
if [ ! -e "/home/bmesh_admin/.my.cnf" ]; then 
    echo "There is no /home/bmesh_admin/.my.cnf file, please create one or do the install old school"
    exit 1
elif [ -z "$MY_SITE_URL" ]; then
    echo "Missing URL"
    exit 1
elif [ -z "$MY_DOCROOT" ]; then
    echo "Missing docroot"
    exit 1
elif [ -z "$MY_DB_NAME" ]; then
    echo "Missing DB name"
    exit 1
elif [ -z "$MY_DB_PASS" ]; then
    echo "Missing DB pass"
    exit 1
elif [ -z "$MY_GRANT_IP" ]; then
    echo "Missing DB IP"
    exit 1
fi
if [ ! -d "$MY_DOCROOT" ]; then
    echo "That docroot does not exist"
    exit 1
fi
if [ ! -z `mysql -e 'show databases' | grep $MY_DB_NAME` ]; then
    echo "That database already exists"
    exit 1
fi
if [ `ls -a $MY_DOCROOT | wc -l` -ne "2" ]; then
    echo "That docroot is not empty"
    exit 1
fi

#DB Config
mysql -e "create database $MY_DB_NAME"
mysql -e "GRANT ALL ON $MY_DB_NAME.* TO '$MY_DB_USER'@'$MY_GRANT_IP' IDENTIFIED BY '$MY_DB_PASS'"
mysql -e 'FLUSH PRIVILEGES, HOSTS'

#Grab Files
wget --quiet -P "$MY_DOCROOT" "$MY_WP_URL"
cd "$MY_DOCROOT"
tar --strip-components=1 -xzf latest.tar.gz
rm -f latest.tar.gz

#Configure Files
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$MY_DB_NAME/" wp-config.php
sed -i "s/username_here/$MY_DB_USER/" wp-config.php
sed -i "s/password_here/$MY_DB_PASS/" wp-config.php
sed -i "s/localhost/$MY_GRANT_IP/" wp-config.php
sed -i "s/put your unique phrase here/$MY_WP_SALT/" wp-config.php

#Permissions
DOCROOT_OWNER="$(stat -c "%U" ${MY_DOCROOT})"
if [ "$DOCROOT_OWNER" == "root" -o "$DOCROOT_OWNER" == "bmesh_admin" ]; then
    echo -e "No bueno - the docroot is owned by $DOCROOT_OWNER please do the needful, chown docroot once install is complete\n"
fi
MY_OWNER="$(stat -c "%U" ${MY_DOCROOT})"
chmod -R 775 wp-content
chown -R $MY_OWNER.apache "$MY_DOCROOT"

#Output
echo -e ""
echo -e "Please visit the URL to finish the wordpress installation\n"
echo -e ""
echo -e "Copy/Paste Info.\n"
echo -e "URL: $MY_SITE_URL"
echo -e "Hosts File Entry: $MY_HOSTS_IP   $MY_SITE_URL www.$MY_SITE_URL\n"
echo -e 'Wordpress User: admin' 
echo -e "Wordpress Pass: $MY_WP_PASS\n" 
echo -e "Docroot: $MY_DOCROOT\n"
echo -e "DB Name: $MY_DB_NAME"
echo -e "DB User: $MY_DB_USER"
echo -e "DB Pass: $MY_DB_PASS"
echo -e "DB Host: $MY_GRANT_IP"
