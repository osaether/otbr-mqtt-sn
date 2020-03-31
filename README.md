
Dockerfile for [OpenThread Border Router](https://openthread.io/guides/border-router) with [Paho MQTT-SN gateway](https://github.com/eclipse/paho.mqtt-sn.embedded-c). 


# Building

```shell 
docker build --no-cache -t otbr-mqtt-sn -f ./Dockerfile .
```

# Running

To run the container with the default parameters:

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

The most common network parameters can be set on the docker command line. The default values are taken from the [Nordic Semiconductor border router](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee/Download#infotabs) such that it works with the examples in the [nRF5 SDK for Thread and Zigbee](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee).
The command line options with default values are shown in the following table.

| Parameter            | Command line option             | Default value                    | Note    |
|----------------------|:--------------------------------|:---------------------------------|:--------|
| Network Name         |  --network-name                 | OTBR-MQTT-SN                     |         |
| NCP Serial Port      |  --ncp-path                     | /dev/ttyACM0                     |         |
| PAN ID               |  --panid                        | 0xABCD                           | 1       |
| Extended PAN ID      |  --xpanid                       | DEAD00BEEF00CAFE                 | 1       |
| NCP Channel          |  --ncp-channel                  | 11                               | 1       |
| Network Key          |  --network-key                  | 00112233445566778899AABBCCDDEEFF | 1       |
| Network PSKc         |  --pskc                         | E00F739803E92CB42DAA7CCE1D2A394D | 1       |
| TUN Interface Name   |  --interface                    | wpan0                            |         |
| NAT64 Prefix         |  --nat64-prefix                 | 64:ff9b::/96                     |         |
| Default prefix route |  --disable-default-prefix-route | Enabled                          |         |
| Default prefix slaac |  --disable-default-prefix-slaac | Enabled                          |         |
| MQTT Broker          |  --broker                       | mqtt.eclipse.org                 |         |

1: These are changed only when the Network Name is changed. To force a change you must change the Network Name.