#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin
MAILTO="noc@blackmesh.com"
MAILFROM="${HOSTNAME}"
MESSAGE="See attached for security scan results"
MAIL="mail -s 'Security scan for $MAILFROM' $EMAIL_ADDRESS < $MESSAGE"


