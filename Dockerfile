ARG MQTT_SN_COMMIT=f2dcda358f21e264de57b47b00ab6165bab4da18

FROM ubuntu:22.04 AS build-mqtt

ARG MQTT_SN_COMMIT

ENV MQTT_SN_REPO=paho.mqtt-sn.embedded-c
ENV MQTT_SN_ZIP=https://github.com/eclipse/"$MQTT_SN_REPO"/archive/"$MQTT_SN_COMMIT".zip

RUN DEBIAN_FRONTEND=noninteractive apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install wget unzip libssl-dev build-essential
RUN DEBIAN_FRONTEND=noninteractive apt -y install libc6-dev-amd64-cross cmake

RUN wget --progress=dot:giga --no-check-certificate -O "$MQTT_SN_REPO".zip "$MQTT_SN_ZIP"
RUN unzip "$MQTT_SN_REPO".zip
RUN rm "$MQTT_SN_REPO".zip
RUN cd "$MQTT_SN_REPO"-"$MQTT_SN_COMMIT"/MQTTSNGateway && ./build.sh udp6

FROM openthread/otbr:latest

ARG MQTT_SN_COMMIT

COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/MQTTSNGateway/bin/MQTT* /app/
COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/MQTTSNGateway/bin/*.conf /app/
COPY --from=build-mqtt /paho.mqtt-sn.embedded-c-"$MQTT_SN_COMMIT"/build.gateway/MQTTSNPacket/src/libMQTTSNPacket.so /usr/local/lib/

ADD docker_entrypoint.sh /app/etc/docker

ENTRYPOINT ["/app/etc/docker/docker_entrypoint.sh"]
