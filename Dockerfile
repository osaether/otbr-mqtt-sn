FROM openthread/otbr:latest

ENV MQTT_SN_REPO=paho.mqtt-sn.embedded-c
ENV MQTT_SN_ZIP=https://github.com/eclipse/"$MQTT_SN_REPO"/archive/develop.zip

RUN DEBIAN_FRONTEND=noninteractive apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install wget unzip libssl-dev

RUN wget --progress=dot:giga --no-check-certificate -O "$MQTT_SN_REPO".zip "$MQTT_SN_ZIP"
RUN unzip "$MQTT_SN_REPO".zip
RUN rm "$MQTT_SN_REPO".zip

RUN cd "$MQTT_SN_REPO"-develop/MQTTSNGateway && sed -i "s/^GatewayUDP6Hops=.*$/GatewayUDP6Hops=64/" gateway.conf
RUN cd "$MQTT_SN_REPO"-develop/MQTTSNGateway && sed -i "s/^GatewayUDP6Port=.*$/GatewayUDP6Port=47193/" gateway.conf
RUN cd "$MQTT_SN_REPO"-develop/MQTTSNGateway && sed -i "s/^GatewayUDP6Broadcast=.*$/GatewayUDP6Broadcast=ff33:40:fdde:ad00:beef:0:0:1/" gateway.conf
RUN cd "$MQTT_SN_REPO"-develop/MQTTSNGateway && make SENSORNET=udp6 && make install

ADD docker_entrypoint.sh /app/borderrouter/script
