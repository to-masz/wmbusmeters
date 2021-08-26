#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json

CONFIG_DATA_PATH=$(bashio::config 'data_path')
CONFIG_CONF="$(jq --raw-output -c -M '.conf' $CONFIG_PATH)"
CONFIG_METERS="$(jq --raw-output -c -M '.meters' $CONFIG_PATH)"

MQTT_HOST=$(bashio::config "mqtt.host")
MQTT_PORT=$(bashio::config "mqtt.port")
MQTT_USER=$(bashio::config "mqtt.username")
MQTT_PASSWORD=$(bashio::config "mqtt.password")

if ! bashio::config.exists 'mqtt.host'; then MQTT_HOST=$(bashio::services mqtt "host"); fi
if ! bashio::config.exists 'mqtt.port'; then MQTT_PORT=$(bashio::services mqtt "port"); fi
if ! bashio::config.exists 'mqtt.username'; then MQTT_USER=$(bashio::services mqtt "username"); fi
if ! bashio::config.exists 'mqtt.password'; then MQTT_PASSWORD=$(bashio::services mqtt "password"); fi

bashio::log.info "Host: ${MQTT_HOST}"
bashio::log.info "Username: ${MQTT_USER}"

echo "Creating mosquitto_pub.sh"
touch /wmbusmeters/mosquitto_pub.sh
echo "#!/usr/bin/with-contenv bashion\n" > /wmbusmeters/mosquitto_pub.sh
echo "TOPIC=$1\n" >> /wmbusmeters/mosquitto_pub.sh
echo "MESSAGE=$2\n\n" >> /wmbusmeters/mosquitto_pub.sh
echo "/usr/bin/mosquitto_pub -h \"${MQTT_HOST}\" -p \"${MQTT_PORT}\" -u \"${MQTT_USER}\" -P \"${MQTT_PASSWORD}\" -t $TOPIC -m \"$MESSAGE\"" >> /wmbusmeters/mosquitto_pub.sh
EOF
chmod a+x /wmbusmeters/mosquitto_pub.sh

echo "Syncing wmbusmeters configuration ..."
[ ! -d $CONFIG_DATA_PATH/logs/meter_readings ] && mkdir -p $CONFIG_DATA_PATH/logs/meter_readings
[ ! -d $CONFIG_DATA_PATH/etc/wmbusmeters.d ] && mkdir -p $CONFIG_DATA_PATH/etc/wmbusmeters.d
echo -e "$CONFIG_CONF" > $CONFIG_DATA_PATH/etc/wmbusmeters.conf 

echo "Registering meters ..."
rm -f $CONFIG_DATA_PATH/etc/wmbusmeters.d/*
meter_no=0
IFS=$'\n'
for meter in $(jq -c -M '.meters[]' $CONFIG_PATH)
do 
    meter_no=$((meter_no+1))
    METER_NAME=$(printf 'meter-%04d' "$(( meter_no ))")
    echo "Adding $METER_NAME ..."
    METER_DATA=$(printf '%s\n' $meter | jq --raw-output -c -M '.') 
    echo -e "$METER_DATA" > $CONFIG_DATA_PATH/etc/wmbusmeters.d/$METER_NAME
done

echo "Running wmbusmeters ..."
/wmbusmeters/wmbusmeters --useconfig=$CONFIG_DATA_PATH
