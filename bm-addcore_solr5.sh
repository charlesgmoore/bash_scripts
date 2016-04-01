##This script will add a single solr core to an existing Solr5 installation
##Charles Moore - BlackMesh 2016

PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"
CORE_NAME="${1}"
HOSTNAME=`hostname`

#Checks
if [ ! -d /opt/solr ]; then 
        echo -e "Solr not installed in /opt/solr...Go manual\n"
        echo -e "Manual steps are: cd into solr_home; sudo -Hu solr bin/solr create -c core_name"
        exit 1
fi
if [ -z "${1}" ]; then
        echo "Usage: ${0} <core_name>"
        exit 1
fi

echo  "${0} <core_name>"
read -p "check syntax matches <enter>"
echo -e "\n#####"

#Running Commands
cd /opt/solr/
sudo -Hu solr bin/solr create -c $CORE_NAME 

#Output
echo -e "
Some things to note:
1. You will probably need to copy fles from the drupal module into the core's conf directory if client asks
2. By default port 8983 is NOT open to the world
3. If client requests 8983 to be open you will want to set up a proxy pass behind htauth
4. The copy paste info below should be sufficient for most clients
5. GO VISUALLY VERIFY CORE AT http://$HOSTNAME:8983/solr
#####"
echo -e "Copy/Paste Info:\n"
echo -e "Host: 127.0.0.1"
echo -e "Port: 8983"
echo -e "Core Name: ${1}"

