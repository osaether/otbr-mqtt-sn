ARG MQTT_SN_COMMIT=07a95121fc40ee74de4695a23518a312fb802fe8

FROM ubuntu:22.04 AS build-mqtt

ARG MQTT_SN_COMMIT

ENV MQTT_SN_REPO=paho.mqtt-sn.embedded-c
ENV MQTT_SN_ZIP=https://github.com/eclipse-paho/"$MQTT_SN_REPO"/archive/"$MQTT_SN_COMMIT".zip

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget unzip libssl-dev build-essential \
        libc6-dev-amd64-cross cmake && \
    rm -rf /var/lib/apt/lists/*

RUN wget --progress=dot:giga --no-check-certificate -O "$MQTT_SN_REPO".zip "$MQTT_SN_ZIP" && \
    unzip "$MQTT_SN_REPO".zip && \
    rm "$MQTT_SN_REPO".zip && \
    cd "$MQTT_SN_REPO"-"$MQTT_SN_COMMIT"/MQTTSNGateway && ./build.sh udp6

FROM openthread/otbr:latest

ARG MQTT_SN_COMMIT

COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/MQTTSNGateway/bin/MQTT* /app/
COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/MQTTSNGateway/bin/*.conf /app/
COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/build.gateway/MQTTSNPacket/src/libMQTTSNPacket.so /usr/local/lib/

ADD docker_entrypoint.sh /app/etc/docker
