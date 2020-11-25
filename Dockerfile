FROM openthread/otbr:latest

ENV MQTT_SN_REPO=paho.mqtt-sn.embedded-c
ENV MQTT_SN_ZIP=https://github.com/eclipse/"$MQTT_SN_REPO"/archive/master.zip

RUN DEBIAN_FRONTEND=noninteractive apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install wget unzip libssl-dev patch build-essential
RUN DEBIAN_FRONTEND=noninteractive apt -y install libc6-dev-amd64-cross

RUN wget --progress=dot:giga --no-check-certificate -O "$MQTT_SN_REPO".zip "$MQTT_SN_ZIP"
RUN unzip "$MQTT_SN_REPO".zip
RUN rm "$MQTT_SN_REPO".zip
RUN cd "$MQTT_SN_REPO"-master/MQTTSNGateway && make SENSORNET=udp6 && make install

ADD docker_entrypoint.sh /app/etc/docker
