#!/bin/bash
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"
HOSTNAME=`hostname`

echo  './vsftpd_install.sh Client_ID ex. 309e password'
read -p "check syntax matches <enter>"

if [ -z $1 ]; then
  echo "You did not specify the Client ID."
  exit 1
elif [ -z $2 ]; then
  echo "You did not specify a password."
  exit 1
fi

#Check service
if [ -d /etc/vsftpd ]; then
        echo 'vsftpd looks like it is already installed'
	exit 1
 else
        echo 'Starting Install...'
fi

#Install necessary packages
yum -y install db4-utils vsftpd

#Set to start on boot
chkconfig vsftpd on

#Propagate conf file
mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.old

echo '# Example config file /etc/vsftpd/vsftpd.conf
#
# The default compiled in settings are fairly paranoid. This sample file
# loosens things up a bit, to make the ftp daemon more usable.
# Please see vsftpd.conf.5 for all compiled in defaults.
#
# READ THIS: This example file is NOT an exhaustive list of vsftpd options.
# Please read the vsftpd.conf.5 manual page to get a full idea of vsftpd'"'"'s
# capabilities.
#
# Allow anonymous FTP? (Beware - allowed by default if you comment this out).
anonymous_enable=NO
#
# Uncomment this to allow local users to log in.
local_enable=YES
#
# Uncomment this to enable any form of FTP write command.
write_enable=YES
#
# Default umask for local users is 077. You may wish to change this to 022,
# if your users expect that (022 is used by most other ftpd'"'"'s)
local_umask=0002
#
# Uncomment this to allow the anonymous FTP user to upload files. This only
# has an effect if the above global write enable is activated. Also, you will
# obviously need to create a directory writable by the FTP user.
anon_upload_enable=YES
#
# Uncomment this if you want the anonymous FTP user to be able to create
# new directories.
anon_mkdir_write_enable=YES
#
# Activate directory messages - messages given to remote users when they
# go into a certain directory.
dirmessage_enable=NO
#
# The target log file can be vsftpd_log_file or xferlog_file.
# This depends on setting xferlog_std_format parameter
xferlog_enable=YES
#
# Make sure PORT transfer connections originate from port 20 (ftp-data).
connect_from_port_20=YES
#
# If you want, you can arrange for uploaded anonymous files to be owned by
# a different user. Note! Using root for uploaded files is not
# recommended!
#chown_uploads=YES
#chown_username=whoever
#
# The name of log file when xferlog_enable=YES and xferlog_std_format=YES
# WARNING - changing this filename affects /etc/logrotate.d/vsftpd.log
#xferlog_file=/var/log/xferlog
#
# Switches between logging into vsftpd_log_file and xferlog_file files.
# NO writes to vsftpd_log_file, YES to xferlog_file
xferlog_std_format=YES
#
# You may change the default value for timing out an idle session.
#idle_session_timeout=600
#
# You may change the default value for timing out a data connection.
#data_connection_timeout=120
#
# It is recommended that you define on your system a unique user which the
# ftp server can use as a totally isolated and unprivileged user.
#nopriv_user=ftpsecure
#
# Enable this and the server will recognise asynchronous ABOR requests. Not
# recommended for security (the code is non-trivial). Not enabling it,
# however, may confuse older FTP clients.
#async_abor_enable=YES
#
# By default the server will pretend to allow ASCII mode but in fact ignore
# the request. Turn on the below options to have the server actually do ASCII
# mangling on files when in ASCII mode.
# Beware that on some FTP servers, ASCII support allows a denial of service
# attack (DoS) via the command "SIZE /big/file" in ASCII mode. vsftpd
# predicted this attack and has always been safe, reporting the size of the
# raw file.
# ASCII mangling is a horrible feature of the protocol.
#ascii_upload_enable=YES
#ascii_download_enable=YES
#
# You may fully customise the login banner string:
#ftpd_banner=Welcome to blah FTP service.
#
# You may specify a file of disallowed anonymous e-mail addresses. Apparently
# useful for combatting certain DoS attacks.
#deny_email_enable=YES
# (default follows)
#banned_email_file=/etc/vsftpd/banned_emails
#
# You may specify an explicit list of local users to chroot() to their home
# directory. If chroot_local_user is YES, then this list becomes a list of
# users to NOT chroot().
#chroot_list_enable=YES
# (default follows)
#chroot_list_file=/etc/vsftpd/chroot_list
#
# You may activate the "-R" option to the builtin ls. This is disabled by
# default to avoid remote users being able to cause excessive I/O on large
# sites. However, some broken FTP clients such as "ncftp" and "mirror" assume
# the presence of the "-R" option, so there is a strong case for enabling it.
#ls_recurse_enable=YES
#
# When "listen" directive is enabled, vsftpd runs in standalone mode and
# listens on IPv4 sockets. This directive cannot be used in conjunction
# with the listen_ipv6 directive.
listen=YES
#
# This directive enables listening on IPv6 sockets. To listen on IPv4 and IPv6
# sockets, you must run two copies of vsftpd whith two configuration files.
# Make sure, that one of the listen options is commented !!
#listen_ipv6=YES
pam_service_name=vsftpd-virtual
userlist_enable=YES
tcp_wrappers=YES
guest_enable=YES
chroot_local_user=YES
anon_other_write_enable=YES
anon_umask=0002
file_open_mode=0666
user_config_dir=/etc/vsftpd/user_conf
#This line allows for resuming transfer
cmds_allowed=ABOR,APPE,CWD,DELE,HELP,LIST,MDTM,MKD,NLST,PASS,PASV,PORT,PWD,QUIT,RETR,RMD,RNFR,RNTO,SIZE,STOR,TYPE,USER,CDUP,SITE,NOOP
#Add virtual_use_local_privs=YES for CHMOD ability' > /etc/vsftpd/vsftpd.conf

#Configure PAM
echo "#%PAM-1.0
auth required pam_userdb.so db=/etc/vsftpd/vsftpd.passwd
account required pam_userdb.so db=/etc/vsftpd/vsftpd.passwd" > /etc/pam.d/vsftpd-virtual

#Setup user/pass
echo -e "$1\n$2" > /etc/vsftpd/vsftpd.passwd.raw

#Reload user DB
db_load -T -t hash -f /etc/vsftpd/vsftpd.passwd.raw /etc/vsftpd/vsftpd.passwd.db

#Secure files
chmod 600 /etc/vsftpd/vsftpd.passwd*

#Chroot Users
mkdir /etc/vsftpd/user_conf

#Create client user
echo "anon_root=/var/www
local_root=/var/www
ftp_username=$1
guest_username=$1" > /etc/vsftpd/user_conf/$1

#Start service
service vsftpd start

#Check service
if [[ `ps aux | grep -v grep | grep vsftpd` ]]; then
	echo 'vsftpd now running'
 else
	echo 'Something went wrong, vsftpd not running'
	exit 1
fi

#Open FW
echo ""
echo "Please be sure to open port 21 on the firewall"
echo ""
echo -e "Copy/Paste Info"
echo -e "Hostname: $HOSTNAME"
echo -e "Port: 21"
echo -e "Username: $1"
echo -e "Password: $2"
echo -e "Jailed to: /var/www/"
echo -e ""
echo -e "Seriously, OPEN THE PORT ON THE FW"


