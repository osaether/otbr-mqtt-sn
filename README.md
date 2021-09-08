
Dockerfile for [OpenThread Border Router](https://openthread.io/guides/border-router) with [Paho MQTT-SN gateway](https://github.com/eclipse/paho.mqtt-sn.embedded-c). 


# Building Docker image

```shell 
docker build --pull --no-cache -t otbr-mqtt-sn -f ./Dockerfile .
```

# Building RCP for the nRF52840 dongle (PCA10059)

```shell
git clone https://github.com/openthread/ot-nrf528xx.git
cd ot-nrf528xx
git submodule update --init
# Skip the following line if you have the GNU Arm Embedded tools installed
./script/bootstrap
./script/build nrf52840 USB_trans -DOT_BOOTLOADER=USB
arm-none-eabi-objcopy -O ihex build/bin/ot-rcp rcp-pca10059.hex
```
See here for instructions on how to program the nRF52840 dongle:
[nRF52840 Dongle Programming Tutorial](https://devzone.nordicsemi.com/nordic/short-range-guides/b/getting-started/posts/nrf52840-dongle-programming-tutorial)

# Running

To run the container with the default parameters:

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

The most common network parameters can be set on the docker command line. The default values are taken from the [Nordic Semiconductor border router](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee/Download#infotabs) such that it works with the examples in the [nRF5 SDK for Thread and Zigbee](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee).
The command line options with default values are shown in the following table.

| Parameter            | Command line option             | Default value                    | 
|----------------------|:--------------------------------|:---------------------------------|
| Network Name         |  --network-name                 | OTBR-MQTT-SN                     |
| RCP Serial Port      |  --radio-url                    | spinel+hdlc+uart:///dev/ttyACM0  |
| PAN ID               |  --panid                        | 0xABCD                           |
| Extended PAN ID      |  --xpanid                       | DEAD00BEEF00CAFE                 |
| Channel              |  --channel                      | 11                               |
| Network Key          |  --network-key                  | 00112233445566778899AABBCCDDEEFF |
| Network PSKc         |  --pskc                         | 5ce66d049d007088ad900dfcc2a55ee3 |
| TUN Interface Name   |  --interface                    | wpan0                            |
| NAT64 Prefix         |  --nat64-prefix                 | 64:ff9b::/96                     |
| Default prefix route |  --disable-default-prefix-route | Enabled                          |
| Default prefix slaac |  --disable-default-prefix-slaac | Enabled                          |
| Backbone Interface   |  --backbone-interface           | eth0                             |
| MQTT Broker          |  --broker                       | mqtt.eclipseprojects.io          |
