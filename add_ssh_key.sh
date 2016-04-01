#!/bin/bash
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"

#Variables
LINUX_USER=''
AUTH_KEY=''
KEY_FILE='.ssh/authorized_keys'
ANSWER=''
HOSTNAME=$(hostname)

#Gather Info
read -p "System User to add key to: " LINUX_USER
read -p "Public Key (plain text copy): " AUTH_KEY
while true; do
read -e -p 'Are you sure all the information is correct? y/n ' -i " y" ANSWER
    case $ANSWER in
        [Yy]* ) echo ''; break;;
        [Nn]* ) echo 'Exiting...'; exit 1;;
        * ) echo 'Please choose y/n. ';;
    esac
done

#Clear carriage returns from AUTH_KEY
AUTH_KEY_CLEAN=$(echo $AUTH_KEY | tr -d '\n\r')

#Check
if [ ! -d /home/$LINUX_USER ]; then
    echo "That user does not have a home directory"
    exit 1
fi

#Install key
if [ -e /home/$LINUX_USER/$KEY_FILE ]; then
    echo $AUTH_KEY_CLEAN >> /home/$LINUX_USER/$KEY_FILE
elif [ ! -e /home/$LINUX_USER/$KEY_FILE ]; then
    mkdir -p /home/$LINUX_USER/.ssh
    echo $AUTH_KEY_CLEAN >> /home/$LINUX_USER/$KEY_FILE
fi

#Sort Permissions
chown -R $LINUX_USER. /home/$LINUX_USER/.ssh
chmod 600 /home/$LINUX_USER/$KEY_FILE
chmod 700 /home/$LINUX_USER/.ssh

#Output
echo '------------'
echo '|Copy/Pasta|'
echo '------------'
echo "Your public key has been added to $HOSTNAME for the $LINUX_USER system user, please see below for details:"
echo -e "Username: $LINUX_USER"
echo 'Permissions on pertinent files are:'
echo $(stat -c %A%U:%G /home/$LINUX_USER/.ssh) "/home/$LINUX_USER/.ssh"
echo $(stat -c %A%U:%G /home/$LINUX_USER/$KEY_FILE) "/home/$LINUX_USER/$KEY_FILE"
echo 'The following key was added: '
echo $AUTH_KEY_CLEAN
echo -e "\n"
echo -e "Please test using: ssh $LINUX_USER@$HOSTNAME"
echo -e "Should there be any issues please send the output of ssh -vvv $LINUX_USER@$HOSTNAME to support@blackmesh.com"
echo -e "\n"
