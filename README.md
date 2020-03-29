
Dockerfile for OpenThread Border Router with MQTT-SN. 


# Building

```shell 
docker build --no-cache -t otbr-mqtt-sn -f ./Dockerfile .
```

# Running

To run the container with the default parameters:

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

The most common network parameters can be set on the docker comman line. The default values are taken from the Nordic Semiconductor border router such that it works with the examples in the [Nordic Semiconductor nRF5 SDK for Thread and Zigbee](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee).
The command line options with default values are shown in the following table.

| Parameter            | command line option             | default value                    |
|----------------------|:--------------------------------|:---------------------------------|
| Network Name         |  --network-name                 | OTBR-MQTT-SN                     |
| NCP Serial Port      |  --ncp-path                     | /dev/ttyACM0                     |
| PAN ID               |  --panid                        | 0xABCD                           |
| Extended PAN ID      |  --xpanid                       | DEAD00BEEF00CAFE                 |
| NCP Channel          |  --ncp-channel                  | 11                               |
| Network Key          |  --network-key                  | 00112233445566778899AABBCCDDEEFF |
| Network PSKc         |  --pskc                         | E00F739803E92CB42DAA7CCE1D2A394D | 
| TUN Interface Name   |  --interface                    | wpan0                            |
| NAT64 Prefix         |  --nat64-prefix                 | 64:ff9b::/96                     |
| Default prefix route |  --disable-default-prefix-route | Enabled                          |
| Default prefix slaac |  --disable-default-prefix-slaac | Enabled                          |

