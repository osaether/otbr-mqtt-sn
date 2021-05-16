FROM ubuntu:18.04 AS build-mqtt

ENV MQTT_SN_REPO=paho.mqtt-sn.embedded-c
ENV MQTT_SN_ZIP=https://github.com/eclipse/"$MQTT_SN_REPO"/archive/master.zip

RUN DEBIAN_FRONTEND=noninteractive apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install wget unzip libssl-dev build-essential
RUN DEBIAN_FRONTEND=noninteractive apt -y install libc6-dev-amd64-cross

WORKDIR /temp

RUN wget --progress=dot:giga --no-check-certificate -O "$MQTT_SN_REPO".zip "$MQTT_SN_ZIP"
RUN unzip "$MQTT_SN_REPO".zip
RUN rm "$MQTT_SN_REPO".zip
RUN cd "$MQTT_SN_REPO"-master/MQTTSNGateway && make SENSORNET=udp6 && make install

FROM openthread/otbr:latest

COPY --from=build-mqtt /temp/MQTT* /app/
COPY --from=build-mqtt /temp/*.conf /app/

ADD docker_entrypoint.sh /app/etc/docker
