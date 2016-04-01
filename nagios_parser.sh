#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bm
esh_admin/bin
OID=someoid
until [ -z $1 ] ; do
        case $1 in
                "-h" )shift;HOST=$1;shift;;
                "-w" )shift;WARN=$1;shift;;
                "-c" )shift;CRIT=$1;shift;;
                * )echo "Unknown option \`${1}' Exiting.";exit 1;;
        esac
done
RESULT=$(snmpget -c bmesh_mon $OID $HOST)
if [ "$?" -ne "0" ] ; then
        echo "SNMP Unknown - No response from ${HOST}"
        exit 3
fi
echo $RESULT | grep -q "No such object"
if [ "$?" -eq "0" ] ; then
        echo "SNMP Unknown - $RESULT"
        exit 3
fi
if [ ${RESULT} -lt "$WARN" ] ; then
        echo "SNMP OK - Connections at ${RESULT}%"
        exit 0
fi

if [ ${RESULT} -ge "$CRIT" ] ; then
        echo "SNMP CRITICAL - Connections at ${RESULT}%"
        exit 2
fi

if [ ${RESULT} -ge "$WARN" ] && [ ${RESULT} -lt "$CRIT" ] ; then
        echo "SNMP WARNNING - Connections at ${RESULT}%"
        exit 1
