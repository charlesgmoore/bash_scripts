#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin

#This script will install rkhunter
#cmoore - Blackmesh 2015

wget -O --quiet /tmp/rkhunter-1.4.2 http://sourceforge.net/projects/rkhunter/files/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz/download

tar -xzf /tmp/rkhunter-1.4.2
/tmp/rkhunter-1.4.2/./installer.sh --layout default --install
/usr/local/bin/rkhunter --update
/usr/local/bin/rkhunter --propupd
