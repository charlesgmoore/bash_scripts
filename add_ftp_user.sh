#!/bin/bash

#This script will accept a username and path, it will generate a password
#and add the appropriate settings into the files necessary for vsftpd

PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"
USER="${1}"
PASSWORD="$(perl -npe "s/[^A-Za-z]//g;" /dev/urandom | head -c 10)"
DIRECTORY="${2}"
HOSTNAME=`hostname`

#Checks
if [ ! -d /etc/vsftpd ]; then 
	echo "Cant find vsftpd config file, ensure it is installed"
	exit 1
fi
if [ -z "${1}" ] || [ -z "${2}" ]; then
	echo "Usage: ${0} user directory_to_jail_to"
	exit 1
fi
if [ ! -d "${2}" ]; then 
	echo "The jail directory does not exist"
	exit 1
fi
if grep -q ${1} /etc/vsftpd/vsftpd.passwd.raw; then
	echo "The FTP user ${1} already exists"
	exit 1
fi

OWNER="$(stat -c "%U" ${DIRECTORY})"

echo  "${0} <user> <directory_to_jail_to>"
read -p "check syntax matches <enter>"
echo ""

#Configure files
echo "$USER" >> /etc/vsftpd/vsftpd.passwd.raw
echo "$PASSWORD" >> /etc/vsftpd/vsftpd.passwd.raw
echo -e "anon_root=$DIRECTORY\nlocal_root=$DIRECTORY\nftp_username=$OWNER\nguest_username=$OWNER" > /etc/vsftpd/user_conf/${1}
db_load -T -t hash -f /etc/vsftpd/vsftpd.passwd.raw /etc/vsftpd/vsftpd.passwd.db

#Output
echo -e "Copy/Paste Info:\n"
echo -e "Host: ${HOSTNAME}"
echo -e "Port: 21"
echo -e "User: ${USER}"
echo -e "Password: ${PASSWORD}"
echo -e "Jailed to: ${DIRECTORY}\n"
echo -e "Please be sure to verify settings\n"
