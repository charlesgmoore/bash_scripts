#!/bin/bash
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/bmesh_admin/bin"

#Variables
MY_MODULUS1=''
MY_MODULUS2=''
MY_INTERMEDIATE=$4
MY_HELP_OPTIONS="
Command line options:\n
    -g        Generate new key/csr pair
    -m        Print modulus of crt/key
    -l        List Subject line: in csr/crt/key/pem
    -s        Generate self-signed cert/key
    -p        Create PEM format
    -i        Intermediate cert filename
    -r        Remove passphrase from key
    -w        Create pfx cert (Windows)
    -h        Print this help menu\n
Example:
   ./csr_tools.sh -m test.com.(crt|key)
   ./csr_tools.sh -p test.com -i intermediate.crt
"

helpme ()
{
echo -e "$MY_HELP_OPTIONS"
}

generate ()
{            
    echo ''
    openssl genrsa -out $OPTARG.key 2048
    echo ''
    openssl req -new -key $OPTARG.key -out $OPTARG.csr
    echo ''
    echo 'CSR for ordering purposes'
    echo ''
    cat $OPTARG.csr
    echo ''
}

modulus ()
{
echo ''
if [[ $OPTARG == *crt ]]; then
    MY_MODULUS1="$(openssl x509 -noout -modulus -in $OPTARG | openssl md5)"
    echo "$MY_MODULUS1 = Certificate Modulus"
elif [[ $OPTARG == *key ]]; then
    MY_MODULUS1="$(openssl rsa -noout -modulus -in $OPTARG | openssl md5)"
    echo "$MY_MODULUS1 = Key Modulus"
else 
    echo 'Please specify cert or key'
fi
    echo ''
}

list ()
{
if [ ! -e $OPTARG ]; then
   echo 'No such file'
   exit 1
fi
if [[ $OPTARG == *csr ]]; then
    echo 'CSR Information'
    openssl req -text -noout -verify -in $OPTARG | grep -m 1 'Subject'
    echo ''
fi
if [[ $OPTARG == *crt ]]; then
    echo 'CRT Information'
    openssl x509 -in $OPTARG -text -noout | grep -m 1 'Subject'
    echo ''
fi
if [[ $OPTARG == *pem ]]; then
    echo 'PEM Information'
    openssl x509 -in $OPTARG -noout -text | grep -m 1 'Subject'
fi
if [[ $OPTARG == *pfx ]]; then
    echo 'PFX Information'
    openssl pkcs12 -info -in $OPTARG | grep -m 1 'Subject'
fi
if [[ $OPTARG == *key ]]; then
    echo "Can't use key file"
    exit 1
fi
}

w_pfx ()
{
if [ ! -e $OPTARG.pem ]; then
    echo 'No pem file in directory'
    exit 1
else
    openssl pkcs12 -inkey $OPTARG.pem -in $OPTARG.crt -export -out $OPTARG.pfx
fi
}

pem ()
{
cat $OPTARG.key $OPTARG.crt $MY_INTERMEDIATE > $OPTARG.pem
}

passphrase ()
{
openssl rsa -in $OPTARG.key -out $OPTARG.key
}

selfsigned ()
{
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout $OPTARG.key -out $OPTARG.crt
}

if [ -z $1 ]; then
    echo ''
    echo 'You did not specify necessary parameters'
    helpme
    exit 1
fi

while getopts g:m:l:s:i:p:w:r:h opt; do
    case $opt in
        g)
            generate
            ;;
        m)
 	    modulus
            ;;
        l)
            list
            ;;
        w)
            w_pfx
            ;;
        i)
            MY_INTERMEDIATE=$OPTARG
            ;;
        p)
            pem
            ;;
        r)
            passphrase
            ;;
        s)
            selfsigned
            ;;
        h)
            helpme
            exit 0
            ;;        
        \?)
            echo "Usage: $0 -h for help"
            exit 1
            ;;
    esac
done
