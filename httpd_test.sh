#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin
## use the facter operatingsystem command and hard code the paths into the script
FACTER=`facter operatingsystem`
if [ "$FACTER" = "CentOS" ]
then
	PATHTO=/etc/httpd/conf/httpd.conf
	SERVICE=/usr/sbin/httpd
	SERVICE_NAME=httpd
elif [ "$FACTER" = "Ubuntu" ]
then
	PATHTO=/etc/apache2/apache2.conf
	SERVICE=/etc/init.d/apache2
	SERVICE_NAME=apache2
else
	echo "SNMP Unknown - Unknown OS"
fi
#This script will check the apache connection limit against number of processes
#if the threshold is reached (90%) or higher, an alert will be generated in Nagios
#
#Set threshold percentage
THRESHOLD=90
WARNING=80
OK=70
#Check the number of active processes
#TOT_PROC=$(ps aux | grep $SERVICE | wc -l)
TOT_PROC=$(lsof -n -P -i|grep ESTABLISHED|grep $SERVICE_NAME | wc -l)	
#
#Find the current setting of MaxClients in /etc/httpd/conf/httpd.conf
MAX_CLIENTS=$(grep -m 1 -i -E "^MaxClients" $PATHTO | sed 's/MaxClients[ \s]*//')
#Find the Max Spare Servers from /etc/httpd/conf/httpd.conf
#MAX_SPARE=$(grep -m 1 -i -E "^MaxSpareServers" /etc/httpd/conf/httpd.conf | sed 's/MaxSpareServers[ \s]*//')
#Subtract idle cliets (MAX_SPARE) from maximum httpd processes (MAX_CLIENTS)
#CLIENTS_FINAL=$[ MAX_CLIENTS - MAX_SPARE ]
#
#Get Ratio of max clients allowed vs. active clients
PERCENT_FINAL=$(echo -| awk "{print $TOT_PROC/$MAX_CLIENTS * 100}")
#
#Bring to whole Number
#PERCENT_FINAL=$(echo "scale=2;$PERCENTAGE * 100" | bc -l)
#
#Check final percentage against the threshold
if [ "$PERCENT_FINAL" -gt "$THRESHOLD" ]
then
	echo "SNMP CRITICAL - Connections at ${PERCENT_FINAL}%"
fi

if [ "$PERCENT_FINAL" -lt "$THRESHOLD" ] && [ "$PERCENT_FINAL" -gt "$WARNING" ]
then
        echo "SNMP WARNING - Connections at ${PERCENT_FINAL}%"
fi

if [ "$PERCENT_FINAL" -lt "$WARNING" ] 
then
	echo "SNMP OK - Connections at ${PERCENT_FINAL}%"
fi

