#!/bin/bash

# This script is called when the docker container of DSI Runtime is started.
# It creates the server configuration files from a WLP configuration template.
# The first argument of the script is the name of the template. By default,
# it is 'dsi-runtime'.

set -e

DSI_HOME="/opt/dsi"

export JAVA_HOME="$DSI_HOME/jdk/jre"
export PATH=$JAVA_HOME/bin:$PATH

if [ -z "$1" ]; then
        DSI_TEMPLATE="dsi-runtime"
else
        DSI_TEMPLATE="$1"
fi

if [ ! -z "$2" ]; then
        DSI_CATALOG_HOSTNAME="$2"
fi

echo "The DSI template $DSI_TEMPLATE is going to be used."

SRV_XML="$DSI_HOME/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.xml"

INTERNAL_IP=`hostname -I| sed 's/ //g'`

if [ ! -f "$SRV_XML" ]; then
        echo "Create the DSI server $DSI_TEMPLATE"
        echo "JAVA_HOME=$JAVA_HOME" > /opt/dsi/runtime/wlp/etc/server.env
        /opt/dsi/runtime/wlp/bin/server create $DSI_TEMPLATE --template=$DSI_TEMPLATE || echo "$DSI_TEMPLATE was already created"
        echo "WLP server $DSI_TEMPLATE has been created"

        echo "" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env
        echo "JAVA_HOME=$JAVA_HOME" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env
else
        echo "$SRV_XML already exist"
fi

if [ ! -z "DSI_CATALOG_HOSTNAME" ]; then
        BOOTSTRAP_FILE=/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/bootstrap.properties
        echo "Modifying $BOOTSTRAP_FILE"
        sed -i "s/ia.bootstrapEndpoints=localhost:2809/ia.bootstrapEndpoints=$DSI_CATALOG_HOSTNAME:2809/g" $BOOTSTRAP_FILE
fi

echo "The IP of the DSI server is $INTERNAL_IP"

sed -i "s/ia\.host\=localhost/ia\.host\=$INTERNAL_IP/" $BOOTSTRAP_FILE
echo "Internal IP: $INTERNAL_IP"

/opt/dsi/runtime/wlp/bin/server run $DSI_TEMPLATE
