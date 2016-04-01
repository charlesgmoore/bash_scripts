#!/bin/bash

DBNAME="$1"
DBPASS="$2"
FILENAME=local.settings.php

if [ -z $1 ]; then
echo "No DB name given"
exit 1
elif [ -z $2 ]; then
echo "No DB Pass given"
exit 1
fi

echo -e '<?php' >> $FILENAME
echo -e '$databases = array(' >> $FILENAME
echo -e "  'default' =>" >> $FILENAME
echo -e '  array (' >> $FILENAME
echo -e "    'default' =>" >> $FILENAME
echo -e '    array (' >> $FILENAME
echo -e "      'driver' => 'mysql'," >> $FILENAME
echo -e "      \"database\" => \"$DBNAME\"" >> $FILENAME
echo -e "      \"username\" => \"$DBNAME\"", >> $FILENAME
echo -e "      \"password\" => \"$DBPASS\"", >> $FILENAME
echo -e "      'port' => ''," >> $FILENAME
echo -e "      'host' => 'db-rw'," >> $FILENAME
echo -e "    )," >> $FILENAME
echo -e "  )," >> $FILENAME
echo -e ");" >> $FILENAME
echo -e "?>" >> $FILENAME
