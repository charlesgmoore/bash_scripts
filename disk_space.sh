#!/bin/bash
#title           :disk_space.sh
#description     :This script will check disk usage and email if passes threshold
#author          :cmoore
#date            :20140518

PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"
IP_ADDRESS="$(curl -s ifconfig.me)"
EMAIL_ADDRESS='maintenance@blackmesh.com'
HOSTNAME="$(hostname)"
TEMP_FILE='/tmp/disk_space.txt'
SEVERE_TEMP_FILE='/tmp/disk_space_24hr.txt'
DU_COMMAND='du -hcx --max-depth=5 / | grep [0-9]G | sort -n -r'
THRESHOLD=90
SEVERE_THRESHOLD=95
PERCENTAGE="$(df / | grep -vE Filesystem | awk '{ print $5 }' | sed 's/%//')"
FREE_SPACE=$(( 100 - PERCENTAGE ))
EMAIL_BODY="Hello,\n 
We have been alerted via our monitoring system that your server: $HOSTNAME ($IP_ADDRESS) is currently at $PERCENTAGE% disk utilization and running out of disk space.\n
Please see below for a list of the top five largest directories on your system (listed recursively).\nOnce any and all unnecessary files have been removed, please respond back so that we may verify your disk usage levels have fallen to acceptable levels.\n 
Alternatively, if you would like to speak to someone about increasing your overall disk space, please feel free to contact BlackMesh Support or someone on our sales team directly at:
BlackMesh Sales 
888.473.0854 x1
sales@blackmesh.com\n

Regards,
Blackmesh"
SEVERE_EMAIL_BODY="Hello,\n
We have been alerted via our monitoring system that your server: $HOSTNAME ($IP_ADDRESS) is currently at $PERCENTAGE% disk utilization.\n
In order to avert any downtime and possible file-system corruption please remove any unneeded files immediately.\n
Please see below for a list of the top five largest directories on your system (listed recursively).\n
Alternatively, if you would like to speak to someone about increasing your overall disk space, please feel free to contact BlackMesh Support or someone on our sales team directly at:
BlackMesh Sales 
888.473.0854 x1
sales@blackmesh.com\n

Regards,
Blackmesh"

function disk_space {
    echo -e '$'"$DU_COMMAND"
    du -hcx --max-depth=5 / | grep [0-9]G | sort -n -r
}
function email_message {
   mail -s "Disk Alert for $HOSTNAME ($IP_ADDRESS) $FREE_SPACE% Free" $EMAIL_ADDRESS
}

if [ -e $TEMP_FILE ] && [[ $PERCENTAGE -lt $THRESHOLD ]]; then
    rm $TEMP_FILE
fi
if [ -e $SEVERE_TEMP_FILE ] && [[ $PERCENTAGE -lt $SEVERE_THRESHOLD ]]; then
    rm $SEVERE_TEMP_FILE
fi
if [ ! -e $TEMP_FILE ] && [[ $PERCENTAGE -ge $THRESHOLD ]]; then
    if [[ $PERCENTAGE -lt $SEVERE_THRESHOLD ]]; then
        echo -e "$EMAIL_BODY\n" >> $TEMP_FILE
        disk_space >> $TEMP_FILE
        email_message < $TEMP_FILE
    fi
fi
if [ ! -e $SEVERE_TEMP_FILE ] && [[ $PERCENTAGE -ge $SEVERE_THRESHOLD ]]; then
    echo -e "$SEVERE_EMAIL_BODY\n" >> $SEVERE_TEMP_FILE
    disk_space >> $SEVERE_TEMP_FILE
    email_message < $SEVERE_TEMP_FILE
fi
