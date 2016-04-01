#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin
FACTER=`facter operatingsystem`

#This is for denyhosts as it does not understand CIDR notation
NON_CIDR="# We mustn't block localhost\n127.0.0.1\n162.249.104.*\n162.249.105.*\n162.249.106.*\n162.249.107.*\n162.249.108.*\n162.249.109.*\n162.249.110.*\n162.249.111.*\n192.88.126.*\n192.88.127.*\n68.64.143.*\n74.121.192.*\n74.121.193.*\n74.121.194.*\n74.121.195.*\n74.121.196.*\n74.121.197.*\n74.121.198.*\n74.121.199.*\n162.220.4.*\n69.174.51.*\n162.220.5.*\n162.220.6.*\n199.167.72.*\n162.220.7.*\n199.167.73.*\n199.167.74.*\n199.167.75.*\n199.167.76.*\n199.167.77.*\n199.167.78.*\n199.167.79.*\n"

#Fail2ban allowed list
CIDR_REPLACE='ignoreip = 127.0.0.1/8 68.64.143.0/24 69.143.51.0/24 162.220.4.0/22 199.167.72.0/21 74.121.192.0/21 162.249.104.0/21'
CIDR_ORIG='ignoreip = 127.0.0.1/8'

MAILTO="noc@blackmesh.com"
MAILFROM="${HOSTNAME}"
MESSAGE="DenyHosts does not seem to be installed, please follow up"
MAIL="mail -s 'Denyhosts Alert for $MAILFROM' $EMAIL_ADDRESS < $MESSAGE"

if [ "$FACTER" = "CentOS" ]; then
    ALLOWED_HOSTS=/var/lib/denyhosts/allowed-hosts
    SERVICE=/etc/init.d/denyhosts
    SERVICE_NAME=denyhosts
    LINES="wc -l $ALLOWED_HOSTS"
    if [ -f $ALLOWED_HOSTS ]; then
        echo -e "$NON_CIDR" > $ALLOWED_HOSTS
        $SERVICE restart
    else
        $MAIL
        exit 1
    fi
elif [ "$FACTER" = "Ubuntu" ]; then
    ALLOWED HOSTS=/etc/fail2ban/jail.conf
    SERVICE=/etc/init.d/fail2ban
    SERVICE_NAME=fail2ban
    if [ -f $ALLOWED_HOSTS ]; then
        sed -i -e "s?$CIDR_ORIG?CIDR_REPLACE?" $ALLOWED_HOSTS
        $SERVICE restart
    else
        $MAIL
        exit 1
fi

