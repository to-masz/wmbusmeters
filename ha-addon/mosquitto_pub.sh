#!/usr/bin/with-contenv bashio

TOPIC=$1
MESSAGE=$2

MQTT_HOST=$(bashio::config "mqtt.host")
if [ -z "$MQTT_HOST"]; then MQTT_HOST=$(bashio::services mqtt "host"); fi
MQTT_PORT=$(bashio::config "mqtt.port")
if [ -z "$MQTT_PORT"]; then MQTT_PORT=$(bashio::services mqtt "port"); fi
MQTT_USER=$(bashio::config "mqtt.username")
if [ -z "$MQTT_USER"]; then MQTT_USER=$(bashio::services mqtt "username"); fi
MQTT_PASSWORD=$(bashio::config "mqtt.password")
if [ -z "$MQTT_PASSWORD"]; then MQTT_PASSWORD=$(bashio::services mqtt "password"); fi

/usr/bin/mosquitto_pub -h $MQTT_HOST -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PASSWORD -t $TOPIC -m "$MESSAGE"